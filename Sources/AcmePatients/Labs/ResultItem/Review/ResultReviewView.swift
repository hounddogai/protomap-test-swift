import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result review.
    final class ResultReviewView {
        var codeText: String
        var label: String
        var patientRef: String
        var specialtyText: String
        var visible: String
        var thresholdText: String
        var statusLabel: String

        init(codeText: String, label: String, patientRef: String, specialtyText: String, visible: String, thresholdText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.patientRef = patientRef
            self.specialtyText = specialtyText
            self.visible = visible
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toResultReviewView(_ item: ResultReview) -> ResultReviewView {
        return ResultReviewView(
            codeText: item.code,
            label: item.label,
            patientRef: item.patientRef,
            specialtyText: Kit.Text.truncate(item.specialty, limit: 120),
            visible: "\(item.visible)",
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultReviewViews(_ items: [ResultReview]) -> [ResultReviewView] {
        var views: [ResultReviewView] = []
        for item in items {
            views.append(toResultReviewView(item))
        }
        return views
    }

    static func sumResultReviewView(_ view: ResultReviewView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
