import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift quota.
    final class ShiftQuotaView {
        var code: String
        var nameText: String
        var bed: String
        var diagnosisCode: String
        var active: String
        var acuityText: String
        var statusLabel: String

        init(code: String, nameText: String, bed: String, diagnosisCode: String, active: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.bed = bed
            self.diagnosisCode = diagnosisCode
            self.active = active
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toShiftQuotaView(_ item: ShiftQuota) -> ShiftQuotaView {
        return ShiftQuotaView(
            code: item.code,
            nameText: item.name,
            bed: item.bed,
            diagnosisCode: item.diagnosisCode,
            active: "\(item.active)",
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftQuotaViews(_ items: [ShiftQuota]) -> [ShiftQuotaView] {
        var views: [ShiftQuotaView] = []
        for item in items {
            views.append(toShiftQuotaView(item))
        }
        return views
    }

    static func sumShiftQuotaView(_ view: ShiftQuotaView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
