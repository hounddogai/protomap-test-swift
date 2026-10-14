import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict read draft.
    final class StrictReadDraftView {
        var code: String
        var titleText: String
        var label: String
        var startsAtText: String
        var maximumText: String
        var name: String
        var unit: String
        var sequence: String
        var statusLabel: String

        init(code: String, titleText: String, label: String, startsAtText: String, maximumText: String, name: String, unit: String, sequence: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.label = label
            self.startsAtText = startsAtText
            self.maximumText = maximumText
            self.name = name
            self.unit = unit
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toStrictReadDraftView(_ item: StrictReadDraft) -> StrictReadDraftView {
        return StrictReadDraftView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 120),
            startsAtText: String(item.startsAt),
            maximumText: String(format: "%.2f", item.maximum),
            name: item.name,
            unit: item.unit,
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictReadDraftViews(_ items: [StrictReadDraft]) -> [StrictReadDraftView] {
        var views: [StrictReadDraftView] = []
        for item in items {
            views.append(toStrictReadDraftView(item))
        }
        return views
    }

    static func sumStrictReadDraftView(_ view: StrictReadDraftView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedStartsAt) + parsedMaximum + Double(parsedSequence)
    }
}
