import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall quota.
    final class RecallQuotaView {
        var code: String
        var title: String
        var pinned: String
        var graceDays: String
        var category: String
        var country: String
        var minimumText: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, title: String, pinned: String, graceDays: String, category: String, country: String, minimumText: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.graceDays = graceDays
            self.category = category
            self.country = country
            self.minimumText = minimumText
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toRecallQuotaView(_ item: RecallQuota) -> RecallQuotaView {
        return RecallQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            pinned: "\(item.pinned)",
            graceDays: String(item.graceDays),
            category: item.category,
            country: item.country,
            minimumText: String(format: "%.2f", item.minimum),
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallQuotaViews(_ items: [RecallQuota]) -> [RecallQuotaView] {
        var views: [RecallQuotaView] = []
        for item in items {
            views.append(toRecallQuotaView(item))
        }
        return views
    }

    static func sumRecallQuotaView(_ view: RecallQuotaView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedGraceDays) + parsedMinimum
    }
}
