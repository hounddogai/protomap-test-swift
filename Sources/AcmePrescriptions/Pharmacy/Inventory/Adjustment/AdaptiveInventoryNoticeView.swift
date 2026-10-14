import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive inventory notice.
    final class AdaptiveInventoryNoticeView {
        var codeText: String
        var titleText: String
        var country: String
        var approvedText: String
        var nameText: String
        var notes: String
        var batchSize: String
        var revisionText: String
        var statusLabel: String

        init(codeText: String, titleText: String, country: String, approvedText: String, nameText: String, notes: String, batchSize: String, revisionText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.country = country
            self.approvedText = approvedText
            self.nameText = nameText
            self.notes = notes
            self.batchSize = batchSize
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveInventoryNoticeView(_ item: AdaptiveInventoryNotice) -> AdaptiveInventoryNoticeView {
        return AdaptiveInventoryNoticeView(
            codeText: item.code,
            titleText: item.title,
            country: item.country,
            approvedText: "\(item.approved)",
            nameText: item.name,
            notes: item.notes,
            batchSize: String(item.batchSize),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveInventoryNoticeViews(_ items: [AdaptiveInventoryNotice]) -> [AdaptiveInventoryNoticeView] {
        var views: [AdaptiveInventoryNoticeView] = []
        for item in items {
            views.append(toAdaptiveInventoryNoticeView(item))
        }
        return views
    }

    static func sumAdaptiveInventoryNoticeView(_ view: AdaptiveInventoryNoticeView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedRevision)
    }
}
