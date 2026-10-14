import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default interaction agreement.
    final class DefaultInteractionAgreementView {
        var code: String
        var title: String
        var graceDays: String
        var sequence: String
        var version: String
        var weightText: String
        var name: String
        var bed: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, title: String, graceDays: String, sequence: String, version: String, weightText: String, name: String, bed: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.sequence = sequence
            self.version = version
            self.weightText = weightText
            self.name = name
            self.bed = bed
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultInteractionAgreementView(_ item: DefaultInteractionAgreement) -> DefaultInteractionAgreementView {
        return DefaultInteractionAgreementView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            graceDays: String(item.graceDays),
            sequence: String(item.sequence),
            version: String(item.version),
            weightText: String(format: "%.2f", item.weight),
            name: item.name,
            bed: item.bed,
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultInteractionAgreementViews(_ items: [DefaultInteractionAgreement]) -> [DefaultInteractionAgreementView] {
        var views: [DefaultInteractionAgreementView] = []
        for item in items {
            views.append(toDefaultInteractionAgreementView(item))
        }
        return views
    }

    static func sumDefaultInteractionAgreementView(_ view: DefaultInteractionAgreementView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedSequence) + Double(parsedVersion)
    }
}
