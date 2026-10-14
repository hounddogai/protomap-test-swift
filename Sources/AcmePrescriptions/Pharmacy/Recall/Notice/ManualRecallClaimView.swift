import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual recall claim.
    final class ManualRecallClaimView {
        var code: String
        var title: String
        var threshold: String
        var procedureCode: String
        var source: String
        var statusLabel: String

        init(code: String, title: String, threshold: String, procedureCode: String, source: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.procedureCode = procedureCode
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toManualRecallClaimView(_ item: ManualRecallClaim) -> ManualRecallClaimView {
        return ManualRecallClaimView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            threshold: String(format: "%.2f", item.threshold),
            procedureCode: item.procedureCode,
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRecallClaimViews(_ items: [ManualRecallClaim]) -> [ManualRecallClaimView] {
        var views: [ManualRecallClaimView] = []
        for item in items {
            views.append(toManualRecallClaimView(item))
        }
        return views
    }

    static func sumManualRecallClaimView(_ view: ManualRecallClaimView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
