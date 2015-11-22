//
//  FieldsPageViewController.swift
//  Hive
//
//  Created by Animesh. on 06/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class FieldsPageViewController: UIViewController, UIPageViewControllerDataSource
{
    //
    // MARK: - Properties & Outlets
    //
    
    private var fieldsPageController: UIPageViewController!
    let fields = Field.getAll()
    
    //
    // MARK: - Methods
    //
    
    private func createPageViewController()
    {
        let pageController = self.storyboard!.instantiateViewControllerWithIdentifier("FieldsPageController") as! UIPageViewController
        pageController.dataSource = self
		
		if fields != nil {
			let startingController = self.storyboard!.instantiateViewControllerWithIdentifier("FieldContentController") as! FieldViewController
			startingController.field = fields![0]
			pageController.setViewControllers([startingController], direction: .Forward, animated: true, completion: nil)
		}
		else {
			let startingController = self.storyboard!.instantiateViewControllerWithIdentifier("noFieldsPageController")
			pageController.setViewControllers([startingController], direction: .Forward, animated: true, completion: nil)
		}
		
        fieldsPageController = pageController
        addChildViewController(fieldsPageController)
        self.view.addSubview(fieldsPageController.view)
        fieldsPageController.didMoveToParentViewController(self)
    }
    
    private func setupPageControl()
    {
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
        appearance.currentPageIndicatorTintColor = UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0)
    }
    
    //
    // MARK: - Page View Controller
    //
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
    {
		if fields == nil
		{
			return self.storyboard!.instantiateViewControllerWithIdentifier("noFieldsPageController")
		}
		
        let fieldController = viewController as! FieldViewController
        
        if ( (fieldController.itemIndex + 1) < fields?.count ) {
            return getFieldController(fieldController.itemIndex+1)
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
		if fields == nil
		{
			return self.storyboard!.instantiateViewControllerWithIdentifier("noFieldsPageController")
		}
        let fieldController = viewController as! FieldViewController
        
        if fieldController.itemIndex > 0 {
            return getFieldController(fieldController.itemIndex - 1)
        }
        
        return nil
    }

    private func getFieldController(itemIndex: Int) -> FieldViewController?
    {
        if itemIndex < fields?.count
        {
            let fieldItemController = self.storyboard!.instantiateViewControllerWithIdentifier("FieldContentController") as! FieldViewController
            fieldItemController.itemIndex = itemIndex
			if fields != nil {
				fieldItemController.field = fields![itemIndex]
			}
            return fieldItemController
        }
        
        return nil
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        if fields != nil {
            return fields!.count
        }
        return 0
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return 0
    }
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	override func viewWillAppear(animated: Bool)
	{
		createPageViewController()
		setupPageControl()
	}

    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
