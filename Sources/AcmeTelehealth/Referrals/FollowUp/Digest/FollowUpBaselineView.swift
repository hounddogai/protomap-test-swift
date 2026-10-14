import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up baseline.
    final class FollowUpBaselineView {
        var codeText: String
        var title: String
        var limit: String
        var copay: String
        var procedureCode: String
        var ward: String
        var createdAtText: String
        var weightText: String
        var pinned: String
        var country: String
        var statusLabel: String

        init(codeText: String, title: String, limit: String, copay: String, procedureCode: String, ward: String, createdAtText: String, weightText: String, pinned: String, country: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.limit = limit
            self.copay = copay
            self.procedureCode = procedureCode
            self.ward = ward
            self.createdAtText = createdAtText
            self.weightText = weightText
            self.pinned = pinned
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpBaselineView(_ item: FollowUpBaseline) -> FollowUpBaselineView {
        return FollowUpBaselineView(
            codeText: item.code,
            title: item.title,
            limit: String(item.limit),
            copay: String(format: "%.2f", item.copay),
            procedureCode: item.procedureCode,
            ward: Kit.Text.truncate(item.ward, limit: 120),
            createdAtText: String(item.createdAt),
            weightText: String(format: "%.2f", item.weight),
            pinned: "\(item.pinned)",
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpBaselineViews(_ items: [FollowUpBaseline]) -> [FollowUpBaselineView] {
        var views: [FollowUpBaselineView] = []
        for item in items {
            views.append(toFollowUpBaselineView(item))
        }
        return views
    }

    static func sumFollowUpBaselineView(_ view: FollowUpBaselineView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedLimit) + parsedCopay + Double(parsedCreatedAt)
    }
}
