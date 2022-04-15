//
//  BuildingViewController.swift
//  TestMapApp
//
//  Created by Tsenguun Batbold on 25/9/20.
//

import UIKit

class BuildingViewController: UIViewController {
    
    @IBOutlet weak var  tableView: UITableView!
    
    var buildingList: Array<Building> = []
    
    var selectedBuildingId = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        fetchBuildings()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show_map" {
            guard let dest = segue.destination as? FCViewController else {return}
            
            dest.buildingId = selectedBuildingId
        
        }
    }
    
    func fetchBuildings() {
        APIService.shared.fetchBuildingList { (response) in
            guard let response = response else {
                return
            }
            
            self.buildingList = response.buildingList
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
    }
    
    @IBAction func showLog(_ sender: Any) {
        let filePath = getDocumentsDirectory().appending("/output.txt")
        print(filePath)
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Create the Array which includes the files you want to share
        var filesToShare = [Any]()

        // Add the path of the file to the Array
        filesToShare.append(fileURL)

        // Make the activityViewContoller which shows the share-view
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)

        // Show the share-view
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension BuildingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buildingList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        
        cell.textLabel?.text = buildingList[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedBuildingId = buildingList[indexPath.row].id
        
        performSegue(withIdentifier: "show_map", sender: self)
    }
    
    
}
