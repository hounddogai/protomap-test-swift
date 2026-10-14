import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy bed board review.
    final class LegacyBedBoardReviewView {
        var codeText: String
        var name: String
        var activeText: String
        var pinned: String
        var sequenceText: String
        var timezone: String
        var quantity: String
        var segmentText: String
        var externalRef: String
        var margin: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, name: String, activeText: String, pinned: String, sequenceText: String, timezone: String, quantity: String, segmentText: String, externalRef: String, margin: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.activeText = activeText
            self.pinned = pinned
            self.sequenceText = sequenceText
            self.timezone = timezone
            self.quantity = quantity
            self.segmentText = segmentText
            self.externalRef = externalRef
            self.margin = margin
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyBedBoardReviewView(_ item: LegacyBedBoardReview) -> LegacyBedBoardReviewView {
        return LegacyBedBoardReviewView(
            codeText: item.code,
            name: item.name,
            activeText: "\(item.active)",
            pinned: "\(item.pinned)",
            sequenceText: String(item.sequence),
            timezone: item.timezone,
            quantity: String(item.quantity),
            segmentText: item.segment,
            externalRef: item.externalRef,
            margin: String(format: "%.2f", item.margin),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyBedBoardReviewViews(_ items: [LegacyBedBoardReview]) -> [LegacyBedBoardReviewView] {
        var views: [LegacyBedBoardReviewView] = []
        for item in items {
            views.append(toLegacyBedBoardReviewView(item))
        }
        return views
    }

    static func sumLegacyBedBoardReviewView(_ view: LegacyBedBoardReviewView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedSequence) + Double(parsedQuantity) + parsedMargin
    }
}
