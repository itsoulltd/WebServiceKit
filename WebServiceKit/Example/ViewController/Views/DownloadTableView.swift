//
//  DownloadTableView.swift
//  Example
//
//  Created by Towhid Islam on 12/1/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import UIKit

class DownloadTableView: UITableView {

    weak var presenter: DownloadPresenter!
    static let TapAnimViewTag = 100012
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dataSource = self
        delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

}

extension DownloadTableView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell") as! DownloadCell
        let model = presenter.dataSource[indexPath.row]
        cell.downloader = presenter.downloader
        cell.updateDisplay(model: model)
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect())
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let model = presenter.dataSource[indexPath.row]
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
        let model = presenter.dataSource[indexPath.row]
        if let _ = model.savedUrl{
            deselectRow( tableView, at: indexPath, animated: true) {
                self.presenter.route(model)
            }
        }
    }
    
    fileprivate func tapAnimView(_ at: CGPoint, indexPath: IndexPath) -> UIView{
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.layer.cornerRadius = 40 / 2
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.4)
        view.center = at
        view.tag = DownloadTableView.TapAnimViewTag
        return view
    }
    
    fileprivate func deselectRow(_ tableView: UITableView, at indexPath: IndexPath, animated: Bool, onCompletion:(() -> Void)?){
        if let cell = tableView.cellForRow(at: indexPath){
            let view = cell.contentView.viewWithTag(DownloadTableView.TapAnimViewTag)
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
            self.presenter.deleteModel(indexPath)
            tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: indexPath.section)], with: UITableViewRowAnimation.automatic)
        }
        delete.backgroundColor = UIColor.orange
        
        return [delete,cancel]
    }
    
}
