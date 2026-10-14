import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff threshold.
    final class HandoffThresholdView {
        var codeText: String
        var titleText: String
        var patientRef: String
        var rateText: String
        var facilityText: String
        var weightText: String
        var version: String
        var minimum: String
        var visible: String
        var refills: String
        var statusLabel: String

        init(codeText: String, titleText: String, patientRef: String, rateText: String, facilityText: String, weightText: String, version: String, minimum: String, visible: String, refills: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.patientRef = patientRef
            self.rateText = rateText
            self.facilityText = facilityText
            self.weightText = weightText
            self.version = version
            self.minimum = minimum
            self.visible = visible
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffThresholdView(_ item: HandoffThreshold) -> HandoffThresholdView {
        return HandoffThresholdView(
            codeText: item.code,
            titleText: item.title,
            patientRef: item.patientRef,
            rateText: String(format: "%.2f", item.rate),
            facilityText: Kit.Text.truncate(item.facility, limit: 80),
            weightText: String(format: "%.2f", item.weight),
            version: String(item.version),
            minimum: String(format: "%.2f", item.minimum),
            visible: "\(item.visible)",
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffThresholdViews(_ items: [HandoffThreshold]) -> [HandoffThresholdView] {
        var views: [HandoffThresholdView] = []
        for item in items {
            views.append(toHandoffThresholdView(item))
        }
        return views
    }

    static func sumHandoffThresholdView(_ view: HandoffThresholdView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedRate + parsedWeight + Double(parsedVersion)
    }
}
