import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness override.
    final class WitnessOverrideView {
        var codeText: String
        var titleText: String
        var segment: String
        var pinned: String
        var ward: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, titleText: String, segment: String, pinned: String, ward: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.segment = segment
            self.pinned = pinned
            self.ward = ward
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessOverrideView(_ item: WitnessOverride) -> WitnessOverrideView {
        return WitnessOverrideView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            segment: item.segment,
            pinned: "\(item.pinned)",
            ward: item.ward,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessOverrideViews(_ items: [WitnessOverride]) -> [WitnessOverrideView] {
        var views: [WitnessOverrideView] = []
        for item in items {
            views.append(toWitnessOverrideView(item))
        }
        return views
    }

    static func sumWitnessOverrideView(_ view: WitnessOverrideView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
