import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled proxy draft.
    final class ScheduledProxyDraftView {
        var code: String
        var nameText: String
        var titleText: String
        var maximumText: String
        var refills: String
        var ratio: String
        var allergy: String
        var statusLabel: String

        init(code: String, nameText: String, titleText: String, maximumText: String, refills: String, ratio: String, allergy: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.titleText = titleText
            self.maximumText = maximumText
            self.refills = refills
            self.ratio = ratio
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledProxyDraftView(_ item: ScheduledProxyDraft) -> ScheduledProxyDraftView {
        return ScheduledProxyDraftView(
            code: item.code,
            nameText: item.name,
            titleText: item.title,
            maximumText: String(format: "%.2f", item.maximum),
            refills: String(item.refills),
            ratio: String(format: "%.2f", item.ratio),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledProxyDraftViews(_ items: [ScheduledProxyDraft]) -> [ScheduledProxyDraftView] {
        var views: [ScheduledProxyDraftView] = []
        for item in items {
            views.append(toScheduledProxyDraftView(item))
        }
        return views
    }

    static func sumScheduledProxyDraftView(_ view: ScheduledProxyDraftView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMaximum + Double(parsedRefills) + parsedRatio
    }
}
