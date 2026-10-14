import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial draft.
    final class DenialDraftView {
        var codeText: String
        var label: String
        var ratio: String
        var graceDays: String
        var marginText: String
        var segment: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, label: String, ratio: String, graceDays: String, marginText: String, segment: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ratio = ratio
            self.graceDays = graceDays
            self.marginText = marginText
            self.segment = segment
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toDenialDraftView(_ item: DenialDraft) -> DenialDraftView {
        return DenialDraftView(
            codeText: item.code,
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            graceDays: String(item.graceDays),
            marginText: String(format: "%.2f", item.margin),
            segment: item.segment,
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialDraftViews(_ items: [DenialDraft]) -> [DenialDraftView] {
        var views: [DenialDraftView] = []
        for item in items {
            views.append(toDenialDraftView(item))
        }
        return views
    }

    static func sumDenialDraftView(_ view: DenialDraftView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedRatio + Double(parsedGraceDays) + parsedMargin
    }
}
