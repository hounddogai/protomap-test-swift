import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default specimen policy.
    final class DefaultSpecimenPolicyView {
        var code: String
        var name: String
        var updatedAtText: String
        var priorityText: String
        var ownerID: String
        var approved: String
        var windowDays: String
        var diagnosisCode: String
        var bed: String
        var statusLabel: String

        init(code: String, name: String, updatedAtText: String, priorityText: String, ownerID: String, approved: String, windowDays: String, diagnosisCode: String, bed: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.updatedAtText = updatedAtText
            self.priorityText = priorityText
            self.ownerID = ownerID
            self.approved = approved
            self.windowDays = windowDays
            self.diagnosisCode = diagnosisCode
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultSpecimenPolicyView(_ item: DefaultSpecimenPolicy) -> DefaultSpecimenPolicyView {
        return DefaultSpecimenPolicyView(
            code: item.code,
            name: item.name,
            updatedAtText: String(item.updatedAt),
            priorityText: String(item.priority),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            approved: "\(item.approved)",
            windowDays: String(item.windowDays),
            diagnosisCode: item.diagnosisCode,
            bed: Kit.Text.truncate(item.bed, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultSpecimenPolicyViews(_ items: [DefaultSpecimenPolicy]) -> [DefaultSpecimenPolicyView] {
        var views: [DefaultSpecimenPolicyView] = []
        for item in items {
            views.append(toDefaultSpecimenPolicyView(item))
        }
        return views
    }

    static func sumDefaultSpecimenPolicyView(_ view: DefaultSpecimenPolicyView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedPriority) + Double(parsedWindowDays)
    }
}
