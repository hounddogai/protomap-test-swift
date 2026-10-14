import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary remittance plan.
    final class PrimaryRemittancePlanView {
        var codeText: String
        var name: String
        var clinicianID: String
        var specialty: String
        var capacity: String
        var reviewerText: String
        var dosageMgText: String
        var statusLabel: String

        init(codeText: String, name: String, clinicianID: String, specialty: String, capacity: String, reviewerText: String, dosageMgText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.capacity = capacity
            self.reviewerText = reviewerText
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRemittancePlanView(_ item: PrimaryRemittancePlan) -> PrimaryRemittancePlanView {
        return PrimaryRemittancePlanView(
            codeText: item.code,
            name: item.name,
            clinicianID: item.clinicianID,
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            capacity: String(item.capacity),
            reviewerText: item.reviewer,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRemittancePlanViews(_ items: [PrimaryRemittancePlan]) -> [PrimaryRemittancePlanView] {
        var views: [PrimaryRemittancePlanView] = []
        for item in items {
            views.append(toPrimaryRemittancePlanView(item))
        }
        return views
    }

    static func sumPrimaryRemittancePlanView(_ view: PrimaryRemittancePlanView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCapacity) + parsedDosageMg
    }
}
