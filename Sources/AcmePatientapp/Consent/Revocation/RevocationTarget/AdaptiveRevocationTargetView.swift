import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive revocation target.
    final class AdaptiveRevocationTargetView {
        var code: String
        var titleText: String
        var floorValueText: String
        var contactEmailText: String
        var sequenceText: String
        var segment: String
        var statusLabel: String

        init(code: String, titleText: String, floorValueText: String, contactEmailText: String, sequenceText: String, segment: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.floorValueText = floorValueText
            self.contactEmailText = contactEmailText
            self.sequenceText = sequenceText
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRevocationTargetView(_ item: AdaptiveRevocationTarget) -> AdaptiveRevocationTargetView {
        return AdaptiveRevocationTargetView(
            code: item.code,
            titleText: item.title,
            floorValueText: String(format: "%.2f", item.floorValue),
            contactEmailText: item.contactEmail,
            sequenceText: String(item.sequence),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRevocationTargetViews(_ items: [AdaptiveRevocationTarget]) -> [AdaptiveRevocationTargetView] {
        var views: [AdaptiveRevocationTargetView] = []
        for item in items {
            views.append(toAdaptiveRevocationTargetView(item))
        }
        return views
    }

    static func sumAdaptiveRevocationTargetView(_ view: AdaptiveRevocationTargetView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedFloorValue + Double(parsedSequence)
    }
}
