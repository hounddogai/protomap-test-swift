import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy bed board template.
    final class LegacyBedBoardTemplateView {
        var codeText: String
        var label: String
        var facility: String
        var createdAtText: String
        var endsAtText: String
        var payer: String
        var statusLabel: String

        init(codeText: String, label: String, facility: String, createdAtText: String, endsAtText: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.facility = facility
            self.createdAtText = createdAtText
            self.endsAtText = endsAtText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyBedBoardTemplateView(_ item: LegacyBedBoardTemplate) -> LegacyBedBoardTemplateView {
        return LegacyBedBoardTemplateView(
            codeText: item.code,
            label: item.label,
            facility: item.facility,
            createdAtText: String(item.createdAt),
            endsAtText: String(item.endsAt),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyBedBoardTemplateViews(_ items: [LegacyBedBoardTemplate]) -> [LegacyBedBoardTemplateView] {
        var views: [LegacyBedBoardTemplateView] = []
        for item in items {
            views.append(toLegacyBedBoardTemplateView(item))
        }
        return views
    }

    static func sumLegacyBedBoardTemplateView(_ view: LegacyBedBoardTemplateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedEndsAt)
    }
}
