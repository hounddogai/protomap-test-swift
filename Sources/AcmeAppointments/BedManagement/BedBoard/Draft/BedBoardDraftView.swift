import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board draft.
    final class BedBoardDraftView {
        var code: String
        var nameText: String
        var payer: String
        var score: String
        var regionText: String
        var phone: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, nameText: String, payer: String, score: String, regionText: String, phone: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payer = payer
            self.score = score
            self.regionText = regionText
            self.phone = phone
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardDraftView(_ item: BedBoardDraft) -> BedBoardDraftView {
        return BedBoardDraftView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            payer: item.payer,
            score: String(format: "%.2f", item.score),
            regionText: item.region,
            phone: item.phone,
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardDraftViews(_ items: [BedBoardDraft]) -> [BedBoardDraftView] {
        var views: [BedBoardDraftView] = []
        for item in items {
            views.append(toBedBoardDraftView(item))
        }
        return views
    }

    static func sumBedBoardDraftView(_ view: BedBoardDraftView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedScore + Double(parsedWindowDays)
    }
}
