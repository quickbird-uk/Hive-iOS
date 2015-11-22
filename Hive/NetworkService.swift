//
//  NetworkService.swift
//  Hive
//
//  Created by Animesh. on 09/09/2015.
//  Copyright © 2015 Quickbird. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

enum HTTPMethod: String
{
    case GET = "GET"
    case POST = "POST"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
}

class NetworkService: NSOperation
{
    //
    // MARK: - Properties
    //
    
    var httpBody: NSString?
    var httpRequest: NSMutableURLRequest
    var httpResponse: NSURLResponse?
    static var offline = !NetworkService.isConnected()
    
    //
    // MARK: - Initializers
    //
    
    init(bodyAsPercentEncodedString body: String?, request: NSMutableURLRequest, token: NSString?)
    {
        self.httpBody = body
        
        // Attach header for POST/PUT requests
        if request.HTTPMethod == "POST" || request.HTTPMethod == "PUT"
        {
			if body != nil
			{
				request.HTTPBody = body!.dataUsingEncoding(NSUTF8StringEncoding)
			}
        }
        self.httpRequest = request
        
        if token != nil
        {
            self.httpRequest.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        }
        
        print("⋮   ⋮  URL                ", terminator:"")
        print(self.httpRequest.URL!)
		print("⋮   ⋮  HTTP METHOD        ", terminator:"")
		print(self.httpRequest.HTTPMethod)
		print("⋮   ⋮  HTTP BODY          ", terminator:"")
		let body = self.httpBody ?? "No body."
		print(body)
    }
    
    convenience init(bodyAsJSON dictionary: NSDictionary?, request: NSMutableURLRequest, token: NSString?)
    {
        if let body = NetworkService.createJSONFrom(dictionary: dictionary)
        {
            self.init(bodyAsPercentEncodedString: body, request: request, token: token)
        }
        else
        {
            self.init(bodyAsPercentEncodedString: nil, request: request, token: token)
        }
    }
    
    convenience init(request: NSMutableURLRequest, token: NSString?)
    {
        self.init(bodyAsPercentEncodedString: nil, request: request, token: token)
    }
    
    //
    // MARK: - JSON Synthesizers
    //

    class func createJSONFrom(dictionary dictionary: NSDictionary?) -> String?
    {
        guard let data = dictionary where NSJSONSerialization.isValidJSONObject(data) else
        {
            print("Provided dictionary is not a valid JSON object.")
            return nil
        }
        
        do
        {
            let json = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions.PrettyPrinted)
            let jsonString = NSString(data: json, encoding: NSUTF8StringEncoding) as? String
            return jsonString
        }
        catch
        {
            print("Couldn't serialize JSON.")
            return nil
        }
    }
    
    class func createJSONFrom(data data: NSData?) -> NSString?
    {
        guard let jsonData = data else
        {
            print("⋮   ⋮  Couldn't create JSON from data. createJSONFrom:data: in NetworkService.swift")
            return nil
        }
        
        let dictionary = NSKeyedUnarchiver.unarchiveObjectWithData(jsonData) as? NSDictionary
        return self.createJSONFrom(dictionary: dictionary)
    }
    
    //
    // MARK: - Methods
    //
    
    func makeHTTPRequest(completion: (JSON?, HiveService.Errors?) -> Void)
    {
        let session = NSURLSession.sharedSession()
        
        let dataTask = session.dataTaskWithRequest(self.httpRequest) {
            (body, header, error) in
            var response: NSHTTPURLResponse?
            var responseBody: JSON?
            
            if body != nil
            {
                responseBody = JSON(data: body!)
                print(responseBody)
            }
            
            if header != nil
            {
                response = (header as! NSHTTPURLResponse)
            }
            
            if response?.statusCode == 200
            {
                completion(responseBody, nil)
            }
            else
            {
                if let errorCode = responseBody?["error"].intValue
                {
                    completion(responseBody, HiveService.Errors(rawValue: errorCode))
                }
                else
                {
                    print("Unknown error.")
                    print("Header. \n \(response)")
                    print("Body. \n \(responseBody)")
                    print("Error. \n \(error)")
                    completion(nil, HiveService.Errors.UnhandledError)
                }
            }
        }
        dataTask.resume()
    }
    
    class func isConnected() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        
        var flags = SCNetworkReachabilityFlags()
        
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags)
        {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}















