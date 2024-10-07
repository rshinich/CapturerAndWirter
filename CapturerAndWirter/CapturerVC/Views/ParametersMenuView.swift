//
//  ParametersMenuView.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/10/5.
//

import UIKit

class ParametersMenuView: UIView {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var formats: [CapturerHelpers.GroupedFormat] = []

    public var didSelectedFormat: ((_ formats: CapturerHelpers.GroupedFormat) -> Void)?

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

    public func updateInfo(formats: [CapturerHelpers.GroupedFormat]) {

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

        cell.textLabel?.text = "\(format.formatKey.width)x\(format.formatKey.height)@\(format.formatKey.maxFrameRate)"
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let format = self.formats[indexPath.row]
        self.didSelectedFormat?(format)
    }
}
