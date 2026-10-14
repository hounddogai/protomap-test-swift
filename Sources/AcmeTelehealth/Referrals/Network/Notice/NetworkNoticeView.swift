import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network notice.
    final class NetworkNoticeView {
        var codeText: String
        var title: String
        var versionText: String
        var maximumText: String
        var contactEmailText: String
        var ownerID: String
        var descriptionText: String
        var segmentText: String
        var statusLabel: String

        init(codeText: String, title: String, versionText: String, maximumText: String, contactEmailText: String, ownerID: String, descriptionText: String, segmentText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.versionText = versionText
            self.maximumText = maximumText
            self.contactEmailText = contactEmailText
            self.ownerID = ownerID
            self.descriptionText = descriptionText
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkNoticeView(_ item: NetworkNotice) -> NetworkNoticeView {
        return NetworkNoticeView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            versionText: String(item.version),
            maximumText: String(format: "%.2f", item.maximum),
            contactEmailText: item.contactEmail,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            descriptionText: item.description,
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkNoticeViews(_ items: [NetworkNotice]) -> [NetworkNoticeView] {
        var views: [NetworkNoticeView] = []
        for item in items {
            views.append(toNetworkNoticeView(item))
        }
        return views
    }

    static func sumNetworkNoticeView(_ view: NetworkNoticeView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedVersion) + parsedMaximum
    }
}
