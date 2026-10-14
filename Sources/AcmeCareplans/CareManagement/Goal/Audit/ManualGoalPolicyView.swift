import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual goal policy.
    final class ManualGoalPolicyView {
        var code: String
        var title: String
        var threshold: String
        var phoneText: String
        var weight: String
        var ceiling: String
        var encounterID: String
        var visitMinutes: String
        var procedureCode: String
        var segmentText: String
        var statusLabel: String

        init(code: String, title: String, threshold: String, phoneText: String, weight: String, ceiling: String, encounterID: String, visitMinutes: String, procedureCode: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.phoneText = phoneText
            self.weight = weight
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toManualGoalPolicyView(_ item: ManualGoalPolicy) -> ManualGoalPolicyView {
        return ManualGoalPolicyView(
            code: item.code,
            title: item.title,
            threshold: String(format: "%.2f", item.threshold),
            phoneText: Kit.Text.truncate(item.phone, limit: 120),
            weight: String(format: "%.2f", item.weight),
            ceiling: String(format: "%.2f", item.ceiling),
            encounterID: item.encounterID,
            visitMinutes: String(item.visitMinutes),
            procedureCode: item.procedureCode,
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualGoalPolicyViews(_ items: [ManualGoalPolicy]) -> [ManualGoalPolicyView] {
        var views: [ManualGoalPolicyView] = []
        for item in items {
            views.append(toManualGoalPolicyView(item))
        }
        return views
    }

    static func sumManualGoalPolicyView(_ view: ManualGoalPolicyView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedThreshold + parsedWeight + parsedCeiling
    }
}
