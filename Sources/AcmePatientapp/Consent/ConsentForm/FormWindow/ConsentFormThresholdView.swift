import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form threshold.
    final class ConsentFormThresholdView {
        var codeText: String
        var title: String
        var allergy: String
        var notes: String
        var floorValue: String
        var label: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, title: String, allergy: String, notes: String, floorValue: String, label: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.allergy = allergy
            self.notes = notes
            self.floorValue = floorValue
            self.label = label
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormThresholdView(_ item: ConsentFormThreshold) -> ConsentFormThresholdView {
        return ConsentFormThresholdView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            allergy: item.allergy,
            notes: Kit.Text.truncate(item.notes, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            label: item.label,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormThresholdViews(_ items: [ConsentFormThreshold]) -> [ConsentFormThresholdView] {
        var views: [ConsentFormThresholdView] = []
        for item in items {
            views.append(toConsentFormThresholdView(item))
        }
        return views
    }

    static func sumConsentFormThresholdView(_ view: ConsentFormThresholdView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
