import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped charge group.
    final class CappedChargeGroupView {
        var codeText: String
        var label: String
        var timezone: String
        var ward: String
        var title: String
        var ownerIDText: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, label: String, timezone: String, ward: String, title: String, ownerIDText: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.timezone = timezone
            self.ward = ward
            self.title = title
            self.ownerIDText = ownerIDText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedChargeGroupView(_ item: CappedChargeGroup) -> CappedChargeGroupView {
        return CappedChargeGroupView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            timezone: item.timezone,
            ward: item.ward,
            title: item.title,
            ownerIDText: item.ownerID,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedChargeGroupViews(_ items: [CappedChargeGroup]) -> [CappedChargeGroupView] {
        var views: [CappedChargeGroupView] = []
        for item in items {
            views.append(toCappedChargeGroupView(item))
        }
        return views
    }

    static func sumCappedChargeGroupView(_ view: CappedChargeGroupView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
