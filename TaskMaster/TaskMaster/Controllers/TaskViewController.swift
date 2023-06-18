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
    
    lazy var dateFormatter: DateFormatter = {
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
        setupUserNameLabel()
        setupDateLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        loadTasks()
        groupTasksByDate()
        self.tableView?.reloadData()
        self.collectionView?.reloadData()
        if let tasks = tasks {
            DataManager.shared.groupTasksByDate(tasks: tasks)
        }
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
        guard let dueDate = task.dueDate else { return }
        self.saveTasks()
    }
    
    func didEditTask(_ task: Task) {
        self.saveTasks()
        self.collectionView.reloadData()
        self.tableView.reloadData()
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
