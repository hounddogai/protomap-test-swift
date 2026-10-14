import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual witness tier.
    final class ManualWitnessTierView {
        var code: String
        var titleText: String
        var batchSize: String
        var approved: String
        var summary: String
        var statusLabel: String

        init(code: String, titleText: String, batchSize: String, approved: String, summary: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.batchSize = batchSize
            self.approved = approved
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toManualWitnessTierView(_ item: ManualWitnessTier) -> ManualWitnessTierView {
        return ManualWitnessTierView(
            code: item.code,
            titleText: item.title,
            batchSize: String(item.batchSize),
            approved: "\(item.approved)",
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualWitnessTierViews(_ items: [ManualWitnessTier]) -> [ManualWitnessTierView] {
        var views: [ManualWitnessTierView] = []
        for item in items {
            views.append(toManualWitnessTierView(item))
        }
        return views
    }

    static func sumManualWitnessTierView(_ view: ManualWitnessTierView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
