import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census segment.
    final class CensusSegmentView {
        var codeText: String
        var label: String
        var refills: String
        var ward: String
        var score: String
        var amount: String
        var notesText: String
        var segmentText: String
        var statusLabel: String

        init(codeText: String, label: String, refills: String, ward: String, score: String, amount: String, notesText: String, segmentText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.refills = refills
            self.ward = ward
            self.score = score
            self.amount = amount
            self.notesText = notesText
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusSegmentView(_ item: CensusSegment) -> CensusSegmentView {
        return CensusSegmentView(
            codeText: item.code,
            label: item.label,
            refills: String(item.refills),
            ward: item.ward,
            score: String(format: "%.2f", item.score),
            amount: String(format: "%.2f", item.amount),
            notesText: Kit.Text.truncate(item.notes, limit: 40),
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusSegmentViews(_ items: [CensusSegment]) -> [CensusSegmentView] {
        var views: [CensusSegmentView] = []
        for item in items {
            views.append(toCensusSegmentView(item))
        }
        return views
    }

    static func sumCensusSegmentView(_ view: CensusSegmentView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedRefills) + parsedScore + parsedAmount
    }
}
