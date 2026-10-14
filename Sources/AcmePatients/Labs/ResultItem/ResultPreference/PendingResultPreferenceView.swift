import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending result preference.
    final class PendingResultPreferenceView {
        var code: String
        var label: String
        var phone: String
        var pinnedText: String
        var ward: String
        var endsAtText: String
        var summary: String
        var floorValue: String
        var visible: String
        var refills: String
        var statusLabel: String

        init(code: String, label: String, phone: String, pinnedText: String, ward: String, endsAtText: String, summary: String, floorValue: String, visible: String, refills: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phone = phone
            self.pinnedText = pinnedText
            self.ward = ward
            self.endsAtText = endsAtText
            self.summary = summary
            self.floorValue = floorValue
            self.visible = visible
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toPendingResultPreferenceView(_ item: PendingResultPreference) -> PendingResultPreferenceView {
        return PendingResultPreferenceView(
            code: item.code,
            label: item.label,
            phone: item.phone,
            pinnedText: "\(item.pinned)",
            ward: item.ward,
            endsAtText: String(item.endsAt),
            summary: item.summary,
            floorValue: String(format: "%.2f", item.floorValue),
            visible: "\(item.visible)",
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingResultPreferenceViews(_ items: [PendingResultPreference]) -> [PendingResultPreferenceView] {
        var views: [PendingResultPreferenceView] = []
        for item in items {
            views.append(toPendingResultPreferenceView(item))
        }
        return views
    }

    static func sumPendingResultPreferenceView(_ view: PendingResultPreferenceView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedEndsAt) + parsedFloorValue + Double(parsedRefills)
    }
}
