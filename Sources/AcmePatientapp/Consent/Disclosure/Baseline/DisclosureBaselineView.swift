import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure baseline.
    final class DisclosureBaselineView {
        var code: String
        var label: String
        var endsAt: String
        var clinicianID: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, endsAt: String, clinicianID: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureBaselineView(_ item: DisclosureBaseline) -> DisclosureBaselineView {
        return DisclosureBaselineView(
            code: item.code,
            label: item.label,
            endsAt: String(item.endsAt),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureBaselineViews(_ items: [DisclosureBaseline]) -> [DisclosureBaselineView] {
        var views: [DisclosureBaselineView] = []
        for item in items {
            views.append(toDisclosureBaselineView(item))
        }
        return views
    }

    static func sumDisclosureBaselineView(_ view: DisclosureBaselineView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedVisitMinutes)
    }
}
