import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default claim target.
    final class DefaultClaimTargetView {
        var codeText: String
        var titleText: String
        var archived: String
        var batchSize: String
        var summary: String
        var approved: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, titleText: String, archived: String, batchSize: String, summary: String, approved: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.archived = archived
            self.batchSize = batchSize
            self.summary = summary
            self.approved = approved
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultClaimTargetView(_ item: DefaultClaimTarget) -> DefaultClaimTargetView {
        return DefaultClaimTargetView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            archived: "\(item.archived)",
            batchSize: String(item.batchSize),
            summary: item.summary,
            approved: "\(item.approved)",
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultClaimTargetViews(_ items: [DefaultClaimTarget]) -> [DefaultClaimTargetView] {
        var views: [DefaultClaimTargetView] = []
        for item in items {
            views.append(toDefaultClaimTargetView(item))
        }
        return views
    }

    static func sumDefaultClaimTargetView(_ view: DefaultClaimTargetView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays)
    }
}
