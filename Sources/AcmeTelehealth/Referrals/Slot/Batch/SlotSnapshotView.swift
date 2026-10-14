import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot snapshot.
    final class SlotSnapshotView {
        var code: String
        var label: String
        var updatedAt: String
        var currency: String
        var visitMinutes: String
        var ward: String
        var specialty: String
        var graceDaysText: String
        var statusLabel: String

        init(code: String, label: String, updatedAt: String, currency: String, visitMinutes: String, ward: String, specialty: String, graceDaysText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.ward = ward
            self.specialty = specialty
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotSnapshotView(_ item: SlotSnapshot) -> SlotSnapshotView {
        return SlotSnapshotView(
            code: item.code,
            label: item.label,
            updatedAt: String(item.updatedAt),
            currency: item.currency,
            visitMinutes: String(item.visitMinutes),
            ward: item.ward,
            specialty: item.specialty,
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotSnapshotViews(_ items: [SlotSnapshot]) -> [SlotSnapshotView] {
        var views: [SlotSnapshotView] = []
        for item in items {
            views.append(toSlotSnapshotView(item))
        }
        return views
    }

    static func sumSlotSnapshotView(_ view: SlotSnapshotView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedVisitMinutes) + Double(parsedGraceDays)
    }
}
