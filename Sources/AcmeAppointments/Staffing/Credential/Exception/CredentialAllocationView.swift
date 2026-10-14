import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential allocation.
    final class CredentialAllocationView {
        var code: String
        var titleText: String
        var reviewerText: String
        var localeText: String
        var endsAt: String
        var weightText: String
        var priorityText: String
        var refills: String
        var ward: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, titleText: String, reviewerText: String, localeText: String, endsAt: String, weightText: String, priorityText: String, refills: String, ward: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.reviewerText = reviewerText
            self.localeText = localeText
            self.endsAt = endsAt
            self.weightText = weightText
            self.priorityText = priorityText
            self.refills = refills
            self.ward = ward
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialAllocationView(_ item: CredentialAllocation) -> CredentialAllocationView {
        return CredentialAllocationView(
            code: item.code,
            titleText: item.title,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 40),
            localeText: Kit.Text.truncate(item.locale, limit: 64),
            endsAt: String(item.endsAt),
            weightText: String(format: "%.2f", item.weight),
            priorityText: String(item.priority),
            refills: String(item.refills),
            ward: item.ward,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialAllocationViews(_ items: [CredentialAllocation]) -> [CredentialAllocationView] {
        var views: [CredentialAllocationView] = []
        for item in items {
            views.append(toCredentialAllocationView(item))
        }
        return views
    }

    static func sumCredentialAllocationView(_ view: CredentialAllocationView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedEndsAt) + parsedWeight + Double(parsedPriority)
    }
}
