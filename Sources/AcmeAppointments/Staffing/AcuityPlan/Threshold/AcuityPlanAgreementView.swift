import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan agreement.
    final class AcuityPlanAgreementView {
        var codeText: String
        var label: String
        var channel: String
        var minimum: String
        var startsAt: String
        var endsAt: String
        var version: String
        var name: String
        var archived: String
        var statusLabel: String

        init(codeText: String, label: String, channel: String, minimum: String, startsAt: String, endsAt: String, version: String, name: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.channel = channel
            self.minimum = minimum
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.version = version
            self.name = name
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanAgreementView(_ item: AcuityPlanAgreement) -> AcuityPlanAgreementView {
        return AcuityPlanAgreementView(
            codeText: item.code,
            label: item.label,
            channel: Kit.Text.truncate(item.channel, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            startsAt: String(item.startsAt),
            endsAt: String(item.endsAt),
            version: String(item.version),
            name: item.name,
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanAgreementViews(_ items: [AcuityPlanAgreement]) -> [AcuityPlanAgreementView] {
        var views: [AcuityPlanAgreementView] = []
        for item in items {
            views.append(toAcuityPlanAgreementView(item))
        }
        return views
    }

    static func sumAcuityPlanAgreementView(_ view: AcuityPlanAgreementView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMinimum + Double(parsedStartsAt) + Double(parsedEndsAt)
    }
}
