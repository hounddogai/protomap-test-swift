import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled handoff window.
    final class ScheduledHandoffWindowView {
        var code: String
        var label: String
        var discount: String
        var clinicianIDText: String
        var currency: String
        var dosageMg: String
        var channelText: String
        var statusLabel: String

        init(code: String, label: String, discount: String, clinicianIDText: String, currency: String, dosageMg: String, channelText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.clinicianIDText = clinicianIDText
            self.currency = currency
            self.dosageMg = dosageMg
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledHandoffWindowView(_ item: ScheduledHandoffWindow) -> ScheduledHandoffWindowView {
        return ScheduledHandoffWindowView(
            code: item.code,
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 64),
            currency: item.currency,
            dosageMg: String(format: "%.2f", item.dosageMg),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledHandoffWindowViews(_ items: [ScheduledHandoffWindow]) -> [ScheduledHandoffWindowView] {
        var views: [ScheduledHandoffWindowView] = []
        for item in items {
            views.append(toScheduledHandoffWindowView(item))
        }
        return views
    }

    static func sumScheduledHandoffWindowView(_ view: ScheduledHandoffWindowView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDiscount + parsedDosageMg
    }
}
