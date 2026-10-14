import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol baseline.
    final class CareProtocolBaselineView {
        var code: String
        var titleText: String
        var rateText: String
        var bedText: String
        var sequence: String
        var archived: String
        var statusLabel: String

        init(code: String, titleText: String, rateText: String, bedText: String, sequence: String, archived: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.rateText = rateText
            self.bedText = bedText
            self.sequence = sequence
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolBaselineView(_ item: CareProtocolBaseline) -> CareProtocolBaselineView {
        return CareProtocolBaselineView(
            code: item.code,
            titleText: item.title,
            rateText: String(format: "%.2f", item.rate),
            bedText: Kit.Text.truncate(item.bed, limit: 120),
            sequence: String(item.sequence),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolBaselineViews(_ items: [CareProtocolBaseline]) -> [CareProtocolBaselineView] {
        var views: [CareProtocolBaselineView] = []
        for item in items {
            views.append(toCareProtocolBaselineView(item))
        }
        return views
    }

    static func sumCareProtocolBaselineView(_ view: CareProtocolBaselineView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedRate + Double(parsedSequence)
    }
}
