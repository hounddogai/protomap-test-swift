import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback worklist review.
    final class FallbackWorklistReviewView {
        var codeText: String
        var nameText: String
        var refills: String
        var patientRef: String
        var batchSize: String
        var notes: String
        var bed: String
        var visibleText: String
        var statusLabel: String

        init(codeText: String, nameText: String, refills: String, patientRef: String, batchSize: String, notes: String, bed: String, visibleText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.refills = refills
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.notes = notes
            self.bed = bed
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackWorklistReviewView(_ item: FallbackWorklistReview) -> FallbackWorklistReviewView {
        return FallbackWorklistReviewView(
            codeText: item.code,
            nameText: item.name,
            refills: String(item.refills),
            patientRef: item.patientRef,
            batchSize: String(item.batchSize),
            notes: item.notes,
            bed: item.bed,
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackWorklistReviewViews(_ items: [FallbackWorklistReview]) -> [FallbackWorklistReviewView] {
        var views: [FallbackWorklistReviewView] = []
        for item in items {
            views.append(toFallbackWorklistReviewView(item))
        }
        return views
    }

    static func sumFallbackWorklistReviewView(_ view: FallbackWorklistReviewView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRefills) + Double(parsedBatchSize)
    }
}
