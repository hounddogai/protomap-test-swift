import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary inventory agreement.
    final class PrimaryInventoryAgreementView {
        var code: String
        var titleText: String
        var countryText: String
        var graceDaysText: String
        var minimumText: String
        var thresholdText: String
        var bed: String
        var weightText: String
        var version: String
        var priority: String
        var statusLabel: String

        init(code: String, titleText: String, countryText: String, graceDaysText: String, minimumText: String, thresholdText: String, bed: String, weightText: String, version: String, priority: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.countryText = countryText
            self.graceDaysText = graceDaysText
            self.minimumText = minimumText
            self.thresholdText = thresholdText
            self.bed = bed
            self.weightText = weightText
            self.version = version
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryInventoryAgreementView(_ item: PrimaryInventoryAgreement) -> PrimaryInventoryAgreementView {
        return PrimaryInventoryAgreementView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            countryText: item.country,
            graceDaysText: String(item.graceDays),
            minimumText: String(format: "%.2f", item.minimum),
            thresholdText: String(format: "%.2f", item.threshold),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            weightText: String(format: "%.2f", item.weight),
            version: String(item.version),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryInventoryAgreementViews(_ items: [PrimaryInventoryAgreement]) -> [PrimaryInventoryAgreementView] {
        var views: [PrimaryInventoryAgreementView] = []
        for item in items {
            views.append(toPrimaryInventoryAgreementView(item))
        }
        return views
    }

    static func sumPrimaryInventoryAgreementView(_ view: PrimaryInventoryAgreementView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedGraceDays) + parsedMinimum + parsedThreshold
    }
}
