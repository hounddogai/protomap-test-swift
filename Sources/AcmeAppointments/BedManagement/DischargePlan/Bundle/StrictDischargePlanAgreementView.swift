import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict discharge plan agreement.
    final class StrictDischargePlanAgreementView {
        var code: String
        var nameText: String
        var endsAtText: String
        var windowDays: String
        var retries: String
        var bedText: String
        var weightText: String
        var phoneText: String
        var checksumText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, nameText: String, endsAtText: String, windowDays: String, retries: String, bedText: String, weightText: String, phoneText: String, checksumText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.endsAtText = endsAtText
            self.windowDays = windowDays
            self.retries = retries
            self.bedText = bedText
            self.weightText = weightText
            self.phoneText = phoneText
            self.checksumText = checksumText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toStrictDischargePlanAgreementView(_ item: StrictDischargePlanAgreement) -> StrictDischargePlanAgreementView {
        return StrictDischargePlanAgreementView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            endsAtText: String(item.endsAt),
            windowDays: String(item.windowDays),
            retries: String(item.retries),
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            weightText: String(format: "%.2f", item.weight),
            phoneText: item.phone,
            checksumText: item.checksum,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictDischargePlanAgreementViews(_ items: [StrictDischargePlanAgreement]) -> [StrictDischargePlanAgreementView] {
        var views: [StrictDischargePlanAgreementView] = []
        for item in items {
            views.append(toStrictDischargePlanAgreementView(item))
        }
        return views
    }

    static func sumStrictDischargePlanAgreementView(_ view: StrictDischargePlanAgreementView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedWindowDays) + Double(parsedRetries)
    }
}
