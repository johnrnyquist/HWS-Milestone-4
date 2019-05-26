import UIKit
import CloudKit

class ViewController: UITableViewController,
                      UIImagePickerControllerDelegate,
                      UINavigationControllerDelegate {
    /* UINavigationControllerDelegate is required because we're using UIImagePickerControllerDelegate */
    
    var people = [Person]()
    
    //MARK: - ViewController class
    
    func doSubmission(name: String, imageURL: URL) {
        let whistleRecord = CKRecord(recordType: "Photo")
        whistleRecord["name"] = name as CKRecordValue
        
        let whistleAsset = CKAsset(fileURL: imageURL)
        whistleRecord["image"] = whistleAsset
        
        CKContainer.default().privateCloudDatabase.save(whistleRecord) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func save() {
        let jsonEncoder = JSONEncoder()
        if let savedData = try? jsonEncoder.encode(people) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "people")
        } else {
            print("Failed to save people.")
        }
    }
    
    func load() {
        let defaults = UserDefaults.standard
        if let savedPeople = defaults.object(forKey: "people") as? Data {
            let jsonDecoder = JSONDecoder()
            do {
                people = try jsonDecoder.decode([Person].self, from: savedPeople)
                print(people.compactMap { ($0.name, $0.imageName) })
                
                
                people.forEach { person in
                    let imagePath = getDocumentsDirectory().appendingPathComponent(person.imageName)
                    self.doSubmission(name: person.name, imageURL: imagePath)
                }
            } catch {
                print("Failed to load people.")
            }
        }
    }
    
    
    //MARK: #selectors
    
    @objc func addNewPerson() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            picker.sourceType = .camera
            present(picker, animated: true)
        } else {
            let ac = UIAlertController(title: "Camera", message: "Camera not available", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(ac, animated: true)
        }
    }
    
    
    
    //MARK: - UIViewController class
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPerson))
        
        load()
    }
    
    
    //MARK: - UIImagePickerControllerDelegate protocol
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName) //create the fully qualified name
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        dismiss(animated: true) {
            let ac = UIAlertController(title: "Name", message: "Enter a name for this person", preferredStyle: .alert)
            ac.addTextField(){ textfield in
                textfield.text = "Unknown"
            }
            let person = Person(name: "Unknown", imageName: imageName)
            ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                guard let newName = ac.textFields?[0].text else { return }
                person.name = newName
                self.people.append(person)
                self.save()
                self.tableView.reloadData()
            })
            self.present(ac, animated: true)
        }
    }
    
    
    //MARK: - UITableViewDataSource protocol
    
    // Tells the data source to return the number of rows in a given section of a table view.
    // This class is the data source.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    // Asks the data source for a cell to insert in a particular location of the table view.
    // This class is the data source.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let path = getDocumentsDirectory().appendingPathComponent(people[indexPath.row].imageName)
        
        /*  Swift lets us use a question mark – textLabel? –
         to mean “do this only if there is an actual text label there,
         or do nothing otherwise.”   */
        cell.textLabel?.text = people[indexPath.row].name /* indexPath: A list of indexes that together represent the path to a specific location in a tree of nested arrays. */
        cell.imageView?.image = UIImage(contentsOfFile: path.path)
        cell.imageView?.layer.borderWidth = 0.5
        cell.imageView?.layer.borderColor = UIColor.lightGray.cgColor
        
        return cell
    }
    
    
    //MARK: - UITableViewDelegate protocol
    
    // Tells the delegate that the specified row is now selected.
    // This class is the delegate.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let detailView = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            
            let path = getDocumentsDirectory().appendingPathComponent(people[indexPath.row].imageName)
            detailView.selectedImagePath = path.path
            detailView.title = "\(indexPath.row + 1) of \(people.count)"
            
            // Pushes a view controller onto the receiver’s stack and updates the display. Note it is animated.
            navigationController?.pushViewController(detailView, animated: true)
        }
    }
}
