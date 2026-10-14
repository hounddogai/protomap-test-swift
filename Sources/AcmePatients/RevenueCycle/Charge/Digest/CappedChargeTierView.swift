import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped charge tier.
    final class CappedChargeTierView {
        var code: String
        var name: String
        var diagnosisCode: String
        var graceDays: String
        var unitText: String
        var durationMinutesText: String
        var clinicianIDText: String
        var endsAtText: String
        var locale: String
        var approved: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCode: String, graceDays: String, unitText: String, durationMinutesText: String, clinicianIDText: String, endsAtText: String, locale: String, approved: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
            self.unitText = unitText
            self.durationMinutesText = durationMinutesText
            self.clinicianIDText = clinicianIDText
            self.endsAtText = endsAtText
            self.locale = locale
            self.approved = approved
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedChargeTierView(_ item: CappedChargeTier) -> CappedChargeTierView {
        return CappedChargeTierView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            diagnosisCode: item.diagnosisCode,
            graceDays: String(item.graceDays),
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            durationMinutesText: String(item.durationMinutes),
            clinicianIDText: item.clinicianID,
            endsAtText: String(item.endsAt),
            locale: item.locale,
            approved: "\(item.approved)",
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedChargeTierViews(_ items: [CappedChargeTier]) -> [CappedChargeTierView] {
        var views: [CappedChargeTierView] = []
        for item in items {
            views.append(toCappedChargeTierView(item))
        }
        return views
    }

    static func sumCappedChargeTierView(_ view: CappedChargeTierView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedDurationMinutes) + Double(parsedEndsAt)
    }
}
