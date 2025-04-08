//
//  SceneDelegate.swift
//  DragAndDropApp
//
//  Created by Mahendra Naidu  on 07/04/25.
//


import UIKit

class ViewController: UIViewController {
    
    // Outlet connected to the collection view in storyboard
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Enum to define sections for the diffable data source
    enum Section {
        case main
    }
    
    // Person model conforming to Hashable for diffable data source
    struct Person: Hashable {
        let id = UUID()      // Unique ID to ensure item uniqueness
        let name: String     // Name to display
    }
    
    // The diffable data source that manages the collection view data
    private var dataSource: UICollectionViewDiffableDataSource<Section, Person>!
    
    // Array of people shown in the collection view
    private var people: [Person] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the collection view layout, cell config, drag/drop behavior
        setupCollectionView()
        
        // Prepare initial static data for the list
        setupData()
        
        // Apply the data snapshot to render items on screen
        applySnapshot()
    }
    
    
    // Prepares static data
    private func setupData() {
        let names = ["Alice", "Bob", "Charlie", "Diana", "Edward", "Fiona"]
        people = names.map { Person(name: $0) }
    }
    
    // Configures collection view layout and cell rendering
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        // Set vertical scroll direction and cell size
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: collectionView.bounds.width - 32, height: 50)
        collectionView.collectionViewLayout = layout
        
        // Register cell
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        
        // Configure data source using diffable snapshot
        dataSource = UICollectionViewDiffableDataSource<Section, Person>(collectionView: collectionView) { (collectionView, indexPath, person) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            cell.contentView.backgroundColor = .systemBlue
            cell.contentView.layer.cornerRadius = 8
            
            // Remove old subviews to avoid duplicates
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Configure label
            let label = UILabel()
            label.text = person.name
            label.textColor = .white
            label.font = .boldSystemFont(ofSize: 16)
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12)
            ])
            
            return cell
        }
    }
    
    // Applies current data to the collection view
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Person>()
        snapshot.appendSections([.main])
        snapshot.appendItems(people, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}


// MARK: -Did Select Item Delegates

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(people[indexPath.row].name)
    }
}

// MARK: - Drag & Drop Delegates

extension ViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    // Provide item to begin drag session
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let person = people[indexPath.item]
        let itemProvider = NSItemProvider(object: person.name as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = person // Store object locally for internal use
        return [dragItem]
    }
    
    // Handle the drop and reordering logic
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath,
              let person = item.dragItem.localObject as? Person else { return }
        
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: people.count - 1, section: 0)
        
        // 🔽 Print order BEFORE drop
        print("🔽 Before Drop:")
        people.forEach { print($0.name) }
        
        // Update array with new order
        collectionView.performBatchUpdates {
            people.remove(at: sourceIndexPath.item)
            people.insert(person, at: destinationIndexPath.item)
        }
        
        // Apply new data to collection view
        applySnapshot()
        
        // Inform coordinator of successful drop
        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        
        // ✅ Print order AFTER drop
        print("✅ After Drop:")
        people.forEach { print($0.name) }
    }
    
    // Allow drop
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    // Set drop behavior: move + insert at destination
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}
