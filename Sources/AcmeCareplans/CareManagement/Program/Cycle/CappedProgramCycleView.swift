import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped program cycle.
    final class CappedProgramCycleView {
        var code: String
        var label: String
        var threshold: String
        var phone: String
        var attemptsText: String
        var version: String
        var allergyText: String
        var unitText: String
        var priority: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, phone: String, attemptsText: String, version: String, allergyText: String, unitText: String, priority: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.phone = phone
            self.attemptsText = attemptsText
            self.version = version
            self.allergyText = allergyText
            self.unitText = unitText
            self.priority = priority
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toCappedProgramCycleView(_ item: CappedProgramCycle) -> CappedProgramCycleView {
        return CappedProgramCycleView(
            code: item.code,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            phone: item.phone,
            attemptsText: String(item.attempts),
            version: String(item.version),
            allergyText: Kit.Text.truncate(item.allergy, limit: 80),
            unitText: item.unit,
            priority: String(item.priority),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedProgramCycleViews(_ items: [CappedProgramCycle]) -> [CappedProgramCycleView] {
        var views: [CappedProgramCycleView] = []
        for item in items {
            views.append(toCappedProgramCycleView(item))
        }
        return views
    }

    static func sumCappedProgramCycleView(_ view: CappedProgramCycleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedThreshold + Double(parsedAttempts) + Double(parsedVersion)
    }
}
