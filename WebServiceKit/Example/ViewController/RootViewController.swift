//
//  ViewController.swift
//  StartupProjectSampleA
//
//  Created by Towhid on 3/16/15.
//  Copyright (c) 2015 Towhid (Selise.ch). All rights reserved.
//

import UIKit
import CoreNetworkStack
import CoreDataStack
import WebServiceKit
import FileSystemSDK

class RootViewController: UIViewController {
    
    static let TapAnimViewTag = 100012
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dataSource: [DownloadCellModel] = [DownloadCellModel]()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var linkInputField: UITextField!
    var writeFile: File? = nil
    
    var vcdownloader: DownloadQueue = {
        var config = RequestQueueConfiguration(identifier: "viewDownloadSynch", info: [RequestQueueConfiguration.Keys.MaxTryCount:2])
        var instance = DownloadQueue(configuration: config)
        instance.restoreState()
        return instance
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        vcdownloader.delegate = self
        //Configure tableView
        if tableView != nil{
            tableView.dataSource = self
            tableView.delegate = self
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        //Load UrlList
        loadUrlList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vcdownloader.activateInternetReachability()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vcdownloader.deactivateInternetReachability()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    fileprivate var URList: [String] = [String]()
    
    fileprivate func loadUrlList(){
        if let urlListPath = Bundle.main.url(forResource: "wallpaper", withExtension: "plist"){
            if let urls = NSArray(contentsOf: urlListPath){
                for item in urls as! [String]{
                    URList.append(item)
                }
            }
        }
    }
    
    private func getRandomUrl() -> String?{
        if URList.count < 0{
            return nil
        }
        //pick a random number based on [0 =< x < URList.count]
        let seed = UInt32(URList.count - 1)
        let x = Int(arc4random_uniform(seed))
        let pickedData = URList[x]
        return pickedData
    }
    
    @IBAction func downloadAction(sender: UIButton) {
        //
        var finalUrl: String?
        if let hitUrl = linkInputField.text as NSString?{
            if (hitUrl.hasPrefix("http://") || hitUrl.hasPrefix("https://")){
                finalUrl = hitUrl as String
            }
            else{
                finalUrl = "http://\(hitUrl)"
            }
        }
        LocalNotificationCenter.stepUpBadgeNumber(forType: "DownloadAction")
        let downloadCap = HttpWebRequest(baseUrl: finalUrl)
        insertModel(forRequest: downloadCap, progress: nil)
    }
    
    @IBAction func proactiveAction(sender: UIButton) {
        //
        if let url = getRandomUrl(){
            LocalNotificationCenter.stepUpBadgeNumber(forType: "DownloadAction")
            let downloadCap = HttpWebRequest(baseUrl: url)
            vcdownloader.enqueueRequest(downloadCap!)
        }
    }
    
    @IBAction func reactiveAction(sender: UIButton) {
        //
        if let url = getRandomUrl(){
            LocalNotificationCenter.stepUpBadgeNumber(forType: "DownloadAction")
            let downloadCap = HttpWebRequest(baseUrl: url)
            insertModel(forRequest: downloadCap, progress: nil)
        }
    }
    
}

extension RootViewController: RequestQueueDelegate{
    
    //MARK: Utility Func
    
    func insertModel(forRequest: HttpWebRequest?, progress: Progress?) {
        //
        let dcm = DownloadCellModel(info: ["request":forRequest!])
        dcm?.progress = progress
        
        //tableDelegate.dataSource.append(dcm)
        //tableView.reloadData()
        
        let lastIndex = dataSource.count
        dataSource.append(dcm!)
        
        DispatchQueue.main.async {
            self.tableView.insertRows(at: [IndexPath(row: lastIndex, section: 0)]
                , with: .top)
        }
    }
    
    func updateDownloadSavePath(forRequest: HttpWebRequest?, savePath: URL?) {
        //
        if let model: DownloadCellModel = findModelFor(request: forRequest){
            model.savedUrl = savePath
        }
        LocalNotificationCenter.stepDownBadgeNumber(forType: "DownloadAction", message: "Download Complete")
    }
    
    //MARK: GenericSynchDelegate
    
    func requestDidSucceed(_ forRequest: HttpWebRequest?, incomming: Data) {
        //
    }
    
    func requestDidFailed(_ forRequest: HttpWebRequest?, error: NSError?) {
        //
    }
    
    func progressListener(_ forRequest: HttpWebRequest?) -> ProgressListener {
        let prog = Progress()
        if let request = forRequest{
            self.insertModel(forRequest: request, progress: prog)
        }
        return prog
    }
    
    func downloadSucceed(_ forRequest: HttpWebRequest?, saveUrl: URL) {
        let fileName = (forRequest?.baseUrl as NSString!).lastPathComponent
        let readFile = File(url: saveUrl)
        let imagesFolder = Folder(name: "Images", searchDirectoryType: FileManager.SearchPathDirectory.cachesDirectory)
        let writePath = imagesFolder.path()?.appendingPathComponent(fileName)
        writeFile = File(url: URL(fileURLWithPath: writePath!))
        writeFile?.writeAsynchFrom(readFile
            , bufferSize: 2048
            , progress: nil
            , completionHandler: { [weak self] (done) in
                if done{
                    print("Secure File Write Successful.")
                    self?.updateDownloadSavePath(forRequest: forRequest, savePath: self?.writeFile?.URL)
                }
                else{
                    print("Secure File Write Failed.")
                }
                let _ = readFile.delete()
        })
    }
    
}

extension RootViewController: UITableViewDataSource, UITableViewDelegate {
    
    func findModelFor(request: HttpWebRequest?) -> DownloadCellModel?{
        //
        var find: DownloadCellModel?
        for model in dataSource{
            if model.request == request{
                find = model
                break
            }
        }
        return find
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell") as! DownloadCell
        let model = dataSource[indexPath.row]
        cell.downloader = vcdownloader
        cell.updateDisplay(model: model)
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect())
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let model = self.dataSource[indexPath.row]
        if let _ = model.savedUrl{
            if let cell = tableView.cellForRow(at: indexPath){
                let view = tapAnimView(cell.contentView.center, indexPath: indexPath)
                cell.contentView.clipsToBounds = true
                cell.contentView.addSubview(view)
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.dataSource[indexPath.row]
        if let _ = model.savedUrl{
            deselectRow( tableView, at: indexPath, animated: true) {
                //TODO: push image viewing controller
                //Following code will go to Router
                let viewController = self.storyboard?.instantiateViewController(withIdentifier: "XImageViewerController") as! XImageViewerController
                viewController.model = model
                if #available(iOS 8.0, *) {
                    self.show(viewController, sender: nil)
                } else {
                    if let nav = self.navigationController{
                        nav.pushViewController(viewController, animated: true)
                    }else{
                        self.modalPresentationStyle = UIModalPresentationStyle.currentContext
                        self.present(viewController, animated: true, completion: nil)
                    }
                }
                //
            }
        }
    }
    
    fileprivate func tapAnimView(_ at: CGPoint, indexPath: IndexPath) -> UIView{
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.layer.cornerRadius = 40 / 2
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.4)
        view.center = at
        view.tag = RootViewController.TapAnimViewTag
        return view
    }
    
    fileprivate func deselectRow(_ tableView: UITableView, at indexPath: IndexPath, animated: Bool, onCompletion:(() -> Void)?){
        if let cell = tableView.cellForRow(at: indexPath){
            let view = cell.contentView.viewWithTag(RootViewController.TapAnimViewTag)
            UIView.animate(withDuration: 0.4, animations: {
                view?.transform = CGAffineTransform(scaleX: 11, y: 11)
            }, completion: { (done) in
                view?.removeFromSuperview()
                if let completion = onCompletion{
                    completion()
                }
            })
        }
    }
    
    //MARK: Swipe to cancel action
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        //
    }
    
    @available(iOS 8.0, *)
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cancel = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Cancel") { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let cell = tableView.cellForRow(at: indexPath) as! DownloadCell
            cell.cancelAction(sender: nil)
        }
        cancel.backgroundColor = UIColor.hex("#1abc9c")
        
        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete") { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let cell = tableView.cellForRow(at: indexPath) as! DownloadCell
            cell.cancelAction(sender: nil)
            self.dataSource.remove(at: indexPath.row)
            tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: indexPath.section)], with: UITableViewRowAnimation.automatic)
        }
        delete.backgroundColor = UIColor.orange
        
        return [delete,cancel]
    }
    
}

