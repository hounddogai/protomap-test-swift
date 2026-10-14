import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form window.
    final class ConsentFormWindowView {
        var code: String
        var labelText: String
        var floorValue: String
        var acuity: String
        var sequence: String
        var maximum: String
        var active: String
        var rate: String
        var margin: String
        var statusLabel: String

        init(code: String, labelText: String, floorValue: String, acuity: String, sequence: String, maximum: String, active: String, rate: String, margin: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.floorValue = floorValue
            self.acuity = acuity
            self.sequence = sequence
            self.maximum = maximum
            self.active = active
            self.rate = rate
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormWindowView(_ item: ConsentFormWindow) -> ConsentFormWindowView {
        return ConsentFormWindowView(
            code: item.code,
            labelText: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            acuity: String(item.acuity),
            sequence: String(item.sequence),
            maximum: String(format: "%.2f", item.maximum),
            active: "\(item.active)",
            rate: String(format: "%.2f", item.rate),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormWindowViews(_ items: [ConsentFormWindow]) -> [ConsentFormWindowView] {
        var views: [ConsentFormWindowView] = []
        for item in items {
            views.append(toConsentFormWindowView(item))
        }
        return views
    }

    static func sumConsentFormWindowView(_ view: ConsentFormWindowView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedFloorValue + Double(parsedAcuity) + Double(parsedSequence)
    }
}
