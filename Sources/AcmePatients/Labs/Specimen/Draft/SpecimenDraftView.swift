import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen draft.
    final class SpecimenDraftView {
        var code: String
        var name: String
        var discountText: String
        var ratio: String
        var visitMinutesText: String
        var limit: String
        var externalRef: String
        var ownerIDText: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, name: String, discountText: String, ratio: String, visitMinutesText: String, limit: String, externalRef: String, ownerIDText: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.discountText = discountText
            self.ratio = ratio
            self.visitMinutesText = visitMinutesText
            self.limit = limit
            self.externalRef = externalRef
            self.ownerIDText = ownerIDText
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenDraftView(_ item: SpecimenDraft) -> SpecimenDraftView {
        return SpecimenDraftView(
            code: item.code,
            name: item.name,
            discountText: String(format: "%.2f", item.discount),
            ratio: String(format: "%.2f", item.ratio),
            visitMinutesText: String(item.visitMinutes),
            limit: String(item.limit),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            ownerIDText: item.ownerID,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenDraftViews(_ items: [SpecimenDraft]) -> [SpecimenDraftView] {
        var views: [SpecimenDraftView] = []
        for item in items {
            views.append(toSpecimenDraftView(item))
        }
        return views
    }

    static func sumSpecimenDraftView(_ view: SpecimenDraftView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedDiscount + parsedRatio + Double(parsedVisitMinutes)
    }
}
