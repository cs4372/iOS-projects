//
//  ViewController.swift
//  TaskMaster
//
//  Created by Catherine Shing on 6/6/23.
//

import UIKit
import CoreData
import ChameleonFramework

class TaskViewController: UIViewController, TaskViewVCDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addTaskButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var tasksByDate: [String: [Task]] = [:]
    
    enum DisplayMode {
        case collection
        case list
    }
    
    var displayMode: DisplayMode = .collection
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var tasks: [Task]?
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.delegate = self
        tableView?.dataSource = self
        
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        setupCollectionView()
        addTaskButton?.layer.cornerRadius = addTaskButton.bounds.width / 2
        setupAddTaskButton()
        loadTasks()
        groupTasksByDate()
        setupUserNameLabel()
        setupDateLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        loadTasks()
    }
    
    private func setupCollectionView() {
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.collectionViewLayout = UICollectionViewFlowLayout()
    }
    
    private func setupUserNameLabel() {
        if let savedUserName = UserDefaults.standard.string(forKey: "UserName") {
            let greeting = "Hi \(savedUserName)!"
            nameLabel?.text = greeting
            nameLabel?.textColor = FlatWatermelon()
        }
    }

    private func setupDateLabel() {
        let dateMessage = "Today is \(DateHelper.formattedDate(from: Date()))"
        dateLabel?.text = dateMessage
        dateLabel?.textColor = FlatSkyBlue()
    }
    
    private func setupAddTaskButton() {
        addTaskButton?.layer.cornerRadius = addTaskButton.bounds.width / 2
        addTaskButton?.clipsToBounds = true
    }
    
    // MARK: Task Operations
    
    func didAddTask(_ task: Task) {
        self.tasks?.append(task)
        self.saveTasks()
        self.collectionView.reloadData()
        self.tableView?.reloadData()
    }
    
    func didEditTask(_ task: Task) {
        self.saveTasks()
        self.collectionView.reloadData()
    }
    
    @IBAction func addTask(_ sender: UIButton) {
        let addTaskViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTaskViewController") as! AddTaskViewController
        addTaskViewController.delegate = self

        presentPanModal(addTaskViewController)
    }
    
    
    @IBAction func toggleCheckbox(_ sender: UIButton) {
        if let cell = sender.superview?.superview as? TaskCollectionViewCell,
            let collectionView = self.collectionView,
            let indexPath = collectionView.indexPath(for: cell) {
                let task = tasks?[indexPath.row]
                task!.isCompleted.toggle()
                saveTasks()
                collectionView.reloadData()
        }
    }
    
    func loadTasks(with request: NSFetchRequest<Task> = Task.fetchRequest(), predicate: NSPredicate? = nil) {
        let sortByDueDate = NSSortDescriptor(key: "dueDate", ascending: true)
          request.sortDescriptors = [sortByDueDate]
          request.predicate = NSPredicate(format: "isCompleted == %d", false)
        
        do {
            tasks = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        self.collectionView?.reloadData()
        tableView?.reloadData()
    }
    
    func saveTasks() {
        do {
            try self.context.save()
        } catch {
            print("Error saving context \(error)")
        }
    }
    
    @IBAction func ViewTypeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
              case 0:
                  displayMode = .collection
              case 1:
                  displayMode = .list
              default:
                  break
              }

        updateViews()
    }
    
    func updateViews() {
         collectionView.isHidden = displayMode == .list
         tableView.isHidden = displayMode == .collection
     }
    
}

// MARK: UICollectionViewDataSource

extension TaskViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if tasks?.count == 0 {
            collectionView.setEmptyView(title: "You don't have any tasks yet!", message: "Click the + button to add some tasks")
        } else {
            collectionView.restore()
        }
        return tasks?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TaskCollectionViewCell", for: indexPath) as! TaskCollectionViewCell
        
        if let task = tasks?[indexPath.row] {
            cell.setup(with: task)
        }
        
        return cell
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension TaskViewController: UICollectionViewDelegateFlowLayout {
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 180, height: 200)
    }
}

// MARK: UICollectionViewDelegate

extension TaskViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let editAction = self.createEditAction(for: indexPath)
            let deleteAction = self.createDeleteAction(for: indexPath)
            
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
        
        return configuration
    }
    
    private func createEditAction(for indexPath: IndexPath) -> UIAction {
        let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] action in
            guard let self = self else { return }
            
            if let editItem = self.tasks?[indexPath.row] {
                let addTaskCV = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTaskViewController") as! AddTaskViewController
                let task = self.tasks?[indexPath.row]
                addTaskCV.delegate = self
                
                if let currentTask = task {
                    addTaskCV.editTask = currentTask
                }
                
                self.presentPanModal(addTaskCV)
            }
        }
        
        return editAction
    }
    
    private func createDeleteAction(for indexPath: IndexPath) -> UIAction {
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] action in
            guard let self = self else { return }
            
            if let deleteItem = self.tasks?[indexPath.row] {
                self.context.delete(deleteItem)
                self.tasks?.remove(at: indexPath.row)
                self.saveTasks()
                self.collectionView.reloadData()
            }
        }
        
        return deleteAction
    }
}

extension TaskViewController: UITableViewDataSource {
    
    func groupTasksByDate() {
        if let tasks {
            for task in tasks {
                guard let dueDate = task.dueDate else { continue }
                
                let dateString = dateFormatter.string(from: dueDate)
                
                if tasksByDate[dateString] == nil {
                    tasksByDate[dateString] = [task]
                } else {
                    tasksByDate[dateString]?.append(task)
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tasksByDate.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dates = Array(tasksByDate.keys)
        let date = dates[section]
        
        if let tasks = tasksByDate[date] {
            return tasks.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDates = Array(tasksByDate.keys)
        let sectionDateString = sectionDates[section]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let sectionDate = dateFormatter.date(from: sectionDateString) {
            return dateFormatter.string(from: sectionDate)
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let sectionDates = Array(self.tasksByDate.keys).sorted()
        let sectionDateString = sectionDates[indexPath.section]
        let tasksForSection = self.tasksByDate[sectionDateString]
        
        DispatchQueue.main.async {
            let task = tasksForSection?[indexPath.row]
            cell.textLabel?.text = task?.title
        }
        return cell
    }
}

extension TaskViewController: UITableViewDelegate {
    
}

