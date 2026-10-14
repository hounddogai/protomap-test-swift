import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback bed board variance.
    final class FallbackBedBoardVarianceView {
        var code: String
        var nameText: String
        var segmentText: String
        var bedText: String
        var title: String
        var channelText: String
        var archived: String
        var sourceText: String
        var payer: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, segmentText: String, bedText: String, title: String, channelText: String, archived: String, sourceText: String, payer: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.segmentText = segmentText
            self.bedText = bedText
            self.title = title
            self.channelText = channelText
            self.archived = archived
            self.sourceText = sourceText
            self.payer = payer
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackBedBoardVarianceView(_ item: FallbackBedBoardVariance) -> FallbackBedBoardVarianceView {
        return FallbackBedBoardVarianceView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            segmentText: item.segment,
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            title: item.title,
            channelText: item.channel,
            archived: "\(item.archived)",
            sourceText: Kit.Text.truncate(item.source, limit: 120),
            payer: Kit.Text.truncate(item.payer, limit: 120),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackBedBoardVarianceViews(_ items: [FallbackBedBoardVariance]) -> [FallbackBedBoardVarianceView] {
        var views: [FallbackBedBoardVarianceView] = []
        for item in items {
            views.append(toFallbackBedBoardVarianceView(item))
        }
        return views
    }

    static func sumFallbackBedBoardVarianceView(_ view: FallbackBedBoardVarianceView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
