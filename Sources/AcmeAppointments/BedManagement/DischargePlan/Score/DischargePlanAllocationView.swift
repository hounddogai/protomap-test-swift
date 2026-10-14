import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan allocation.
    final class DischargePlanAllocationView {
        var codeText: String
        var title: String
        var patientRef: String
        var specialty: String
        var clinicianID: String
        var endsAt: String
        var payer: String
        var phone: String
        var notes: String
        var startsAtText: String
        var budget: String
        var statusLabel: String

        init(codeText: String, title: String, patientRef: String, specialty: String, clinicianID: String, endsAt: String, payer: String, phone: String, notes: String, startsAtText: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.patientRef = patientRef
            self.specialty = specialty
            self.clinicianID = clinicianID
            self.endsAt = endsAt
            self.payer = payer
            self.phone = phone
            self.notes = notes
            self.startsAtText = startsAtText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanAllocationView(_ item: DischargePlanAllocation) -> DischargePlanAllocationView {
        return DischargePlanAllocationView(
            codeText: item.code,
            title: item.title,
            patientRef: item.patientRef,
            specialty: item.specialty,
            clinicianID: item.clinicianID,
            endsAt: String(item.endsAt),
            payer: item.payer,
            phone: item.phone,
            notes: item.notes,
            startsAtText: String(item.startsAt),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanAllocationViews(_ items: [DischargePlanAllocation]) -> [DischargePlanAllocationView] {
        var views: [DischargePlanAllocationView] = []
        for item in items {
            views.append(toDischargePlanAllocationView(item))
        }
        return views
    }

    static func sumDischargePlanAllocationView(_ view: DischargePlanAllocationView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedStartsAt) + parsedBudget
    }
}
