import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding segment.
    final class RoundingSegmentView {
        var codeText: String
        var nameText: String
        var limitText: String
        var procedureCodeText: String
        var weightText: String
        var externalRefText: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, nameText: String, limitText: String, procedureCodeText: String, weightText: String, externalRefText: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.limitText = limitText
            self.procedureCodeText = procedureCodeText
            self.weightText = weightText
            self.externalRefText = externalRefText
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingSegmentView(_ item: RoundingSegment) -> RoundingSegmentView {
        return RoundingSegmentView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            limitText: String(item.limit),
            procedureCodeText: item.procedureCode,
            weightText: String(format: "%.2f", item.weight),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 120),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingSegmentViews(_ items: [RoundingSegment]) -> [RoundingSegmentView] {
        var views: [RoundingSegmentView] = []
        for item in items {
            views.append(toRoundingSegmentView(item))
        }
        return views
    }

    static func sumRoundingSegmentView(_ view: RoundingSegmentView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedLimit) + parsedWeight + Double(parsedVisitMinutes)
    }
}
