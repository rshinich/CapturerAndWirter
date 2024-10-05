//
//  ParametersMenuView.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/10/5.
//

import UIKit
import AVFoundation

class ParametersMenuView: UIView {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var formats: [AVCaptureDevice.Format] = []

    public var didSelectedFormat: ((_ format: AVCaptureDevice.Format) -> Void)?

    // MARK: -

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateInfo(formats: [AVCaptureDevice.Format]) {

        self.formats = formats
        self.tableView.reloadData()
    }
}

extension ParametersMenuView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return self.formats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")

        let format = self.formats[indexPath.row]

        cell.textLabel?.text = format.description
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let format = self.formats[indexPath.row]
        self.didSelectedFormat?(format)
    }
}
