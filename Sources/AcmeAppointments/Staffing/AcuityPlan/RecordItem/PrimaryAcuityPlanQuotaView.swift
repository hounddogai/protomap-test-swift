import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary acuity plan quota.
    final class PrimaryAcuityPlanQuotaView {
        var codeText: String
        var label: String
        var capacity: String
        var budget: String
        var description: String
        var externalRef: String
        var specialty: String
        var minimumText: String
        var clinicianID: String
        var reviewer: String
        var statusLabel: String

        init(codeText: String, label: String, capacity: String, budget: String, description: String, externalRef: String, specialty: String, minimumText: String, clinicianID: String, reviewer: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.capacity = capacity
            self.budget = budget
            self.description = description
            self.externalRef = externalRef
            self.specialty = specialty
            self.minimumText = minimumText
            self.clinicianID = clinicianID
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAcuityPlanQuotaView(_ item: PrimaryAcuityPlanQuota) -> PrimaryAcuityPlanQuotaView {
        return PrimaryAcuityPlanQuotaView(
            codeText: item.code,
            label: item.label,
            capacity: String(item.capacity),
            budget: String(format: "%.2f", item.budget),
            description: item.description,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            specialty: item.specialty,
            minimumText: String(format: "%.2f", item.minimum),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAcuityPlanQuotaViews(_ items: [PrimaryAcuityPlanQuota]) -> [PrimaryAcuityPlanQuotaView] {
        var views: [PrimaryAcuityPlanQuotaView] = []
        for item in items {
            views.append(toPrimaryAcuityPlanQuotaView(item))
        }
        return views
    }

    static func sumPrimaryAcuityPlanQuotaView(_ view: PrimaryAcuityPlanQuotaView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedCapacity) + parsedBudget + parsedMinimum
    }
}
