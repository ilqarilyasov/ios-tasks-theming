//
//  TasksTableViewController.swift
//  Tasks
//
//  Created by Andrew R Madsen on 8/11/18.
//  Copyright © 2018 Andrew R Madsen. All rights reserved.
//

import UIKit
import CoreData

class TasksTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    @IBAction func refresh(_ sender: Any) {
        taskController.fetchTasksFromServer { _ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleTableView()
        Appearance.setLogo(navigationItem: self.navigationItem)
    }
    
    
    /// Style cell
    func styleCell(cell: UITableViewCell) {
        let font = Appearance.setLibelFont(textStyle: .footnote, size: 20)
        cell.textLabel?.font = UIFontMetrics.default.scaledFont(for: font)
        cell.textLabel?.textColor = Appearance.udacityPurple
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        let subFont = Appearance.setLibelFont(textStyle: .footnote, size: 15)
        cell.detailTextLabel?.font = UIFontMetrics.default.scaledFont(for: subFont)
        cell.detailTextLabel?.textColor = Appearance.udacityPurple
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
    }
    
    /// Style bar button
    func styleBarButton(){
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.backgroundColor = Appearance.robinhoodPink
        button.layer.cornerRadius = button.frame.height/2
        button.layer.masksToBounds = true
        let rightBButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = rightBButton
    }
    
    /// Style tableViewHeaderFooter
    func styleTableView() {
        let newView = UIView()
        newView.backgroundColor = Appearance.redColor
        tableView.tableHeaderView?.backgroundColor = Appearance.redColor
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        
        let task = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = task.name
        cell.detailTextLabel?.text = task.notes
        
        switch task.priority {
        case "critical":
            cell.backgroundColor = Appearance.redColor
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.textColor = UIColor.white
        case "high":
            cell.backgroundColor = Appearance.purpleColor
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.textColor = UIColor.white
        case "normal":
            cell.backgroundColor = Appearance.blueColor
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.textColor = UIColor.white
        case "low":
            cell.backgroundColor = Appearance.greenColor
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.textColor = UIColor.white
        default:
            break
        }
        
        //styleCell(cell: cell)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { return nil }
        let sectionTitle = sectionInfo.name.capitalized
        
        return  sectionTitle
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = fetchedResultsController.object(at: indexPath)
            
            taskController.deleteTaskFromServer(task) { (error) in
                if let error = error {
                    NSLog("Error deleting task from server: \(error.localizedDescription)")
                    return
                }
            
                DispatchQueue.main.async {
                    let moc = CoreDataStack.shared.mainContext
                    moc.delete(task)
                    do {
                        try moc.save()
                    } catch {
                        moc.reset()
                        NSLog("Error saving managed object context: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowTaskDetail" {
            let detailVC = segue.destination as! TaskDetailViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                detailVC.task = fetchedResultsController.object(at: indexPath)
            }
            detailVC.taskController = taskController
        }
        
        if segue.identifier == "ShowCreateTask" {
            let detailVC = segue.destination as! TaskDetailViewController
            detailVC.taskController = taskController
        }
    }
    
    // MARK: Properties
    
    private let taskController = TaskController()
    
    lazy var fetchedResultsController: NSFetchedResultsController<Task> = {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: true),
                                        NSSortDescriptor(key: "name", ascending: true)]
        let moc = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: "priority", cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
}
