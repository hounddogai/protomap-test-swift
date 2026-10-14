import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness group.
    final class WitnessGroupView {
        var codeText: String
        var labelText: String
        var description: String
        var facility: String
        var rate: String
        var statusLabel: String

        init(codeText: String, labelText: String, description: String, facility: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.description = description
            self.facility = facility
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessGroupView(_ item: WitnessGroup) -> WitnessGroupView {
        return WitnessGroupView(
            codeText: item.code,
            labelText: item.label,
            description: Kit.Text.truncate(item.description, limit: 120),
            facility: item.facility,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessGroupViews(_ items: [WitnessGroup]) -> [WitnessGroupView] {
        var views: [WitnessGroupView] = []
        for item in items {
            views.append(toWitnessGroupView(item))
        }
        return views
    }

    static func sumWitnessGroupView(_ view: WitnessGroupView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
