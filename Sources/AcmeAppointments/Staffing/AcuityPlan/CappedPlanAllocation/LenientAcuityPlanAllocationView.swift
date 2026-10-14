import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient acuity plan allocation.
    final class LenientAcuityPlanAllocationView {
        var codeText: String
        var title: String
        var visitMinutes: String
        var clinicianID: String
        var durationMinutesText: String
        var facilityText: String
        var ownerIDText: String
        var statusLabel: String

        init(codeText: String, title: String, visitMinutes: String, clinicianID: String, durationMinutesText: String, facilityText: String, ownerIDText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.visitMinutes = visitMinutes
            self.clinicianID = clinicianID
            self.durationMinutesText = durationMinutesText
            self.facilityText = facilityText
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientAcuityPlanAllocationView(_ item: LenientAcuityPlanAllocation) -> LenientAcuityPlanAllocationView {
        return LenientAcuityPlanAllocationView(
            codeText: item.code,
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            clinicianID: item.clinicianID,
            durationMinutesText: String(item.durationMinutes),
            facilityText: Kit.Text.truncate(item.facility, limit: 40),
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientAcuityPlanAllocationViews(_ items: [LenientAcuityPlanAllocation]) -> [LenientAcuityPlanAllocationView] {
        var views: [LenientAcuityPlanAllocationView] = []
        for item in items {
            views.append(toLenientAcuityPlanAllocationView(item))
        }
        return views
    }

    static func sumLenientAcuityPlanAllocationView(_ view: LenientAcuityPlanAllocationView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedDurationMinutes)
    }
}
