//
//  TaskListsViewController.swift
//  ToDoListRealm
//
//  Created by Snow Lukin on 30.01.2022.
//

import UIKit
import RealmSwift

class TaskListViewController: UITableViewController {
    
    private var taskLists: Results<TaskList>!
    private var filteredTaskLists: Results<TaskList>!
    private var isSorted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskLists = StorageManager.shared.realm.objects(TaskList.self)
        filteredTaskLists = StorageManager.shared.realm.objects(TaskList.self).sorted(byKeyPath: "name", ascending: true)
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        
        navigationItem.rightBarButtonItem = addButton
        navigationItem.leftBarButtonItem = editButtonItem
        
        createTempData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @IBAction func sortingList(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            isSorted = false
            tableView.reloadData()
        default:
            isSorted = true
            tableView.reloadData()
        }
    }
    
    @objc private func  addButtonPressed() {
        showAlert()
    }
}

// MARK: - Navigation
extension TaskListViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        guard let tasksVC = segue.destination as? TasksViewController else { return }
        let taskList = taskLists[indexPath.row]
        tasksVC.taskList = taskList
    }
}

// MARK: - Table View Data Source
extension TaskListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath) as! TaskListCell
        let taskList = isSorted ? filteredTaskLists[indexPath.row] : taskLists[indexPath.row]
        let uncompletedTasks = taskList.tasks.filter({ !$0.isComplete })
        
        cell.titleLabel.text = taskList.name
        
        if uncompletedTasks.count == 0 {
            cell.secondaryText.isHidden = true
            cell.checkmarkImage.isHidden = false
        } else {
            cell.secondaryText.isHidden = false
            cell.secondaryText.text = "\(uncompletedTasks.count)"
            cell.checkmarkImage.isHidden = true
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: taskList) {
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { _, _, isDone in
            StorageManager.shared.done(taskList)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
}

// MARK: - Data
extension TaskListViewController {
    
    private func createTempData() {
        DataManager.shared.createTempDataV2 {
            self.tableView.reloadData()
        }
    }
    
    private func save(taskList: String) {
        let taskList = TaskList(value: [taskList])
        StorageManager.shared.save(taskList)
        
        let rowIndex = IndexPath(row: taskLists.index(of: taskList) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
}

// MARK: - AlertController
extension TaskListViewController {
    
    private func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let title = taskList != nil ? "Edit List" : "New List"
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "Please set title for new task list")
        
        alert.action(with: taskList) { newValue in
            if let taskList = taskList, let completion = completion {
                StorageManager.shared.edit(taskList, newValue: newValue)
                completion()
            } else {
                self.save(taskList: newValue)
            }
        }
        
        present(alert, animated: true)
    }
}
