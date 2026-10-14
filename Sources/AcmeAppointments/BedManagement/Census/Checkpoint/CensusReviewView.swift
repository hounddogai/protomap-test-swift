import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census review.
    final class CensusReviewView {
        var code: String
        var nameText: String
        var labelText: String
        var durationMinutes: String
        var procedureCodeText: String
        var weightText: String
        var statusLabel: String

        init(code: String, nameText: String, labelText: String, durationMinutes: String, procedureCodeText: String, weightText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.labelText = labelText
            self.durationMinutes = durationMinutes
            self.procedureCodeText = procedureCodeText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusReviewView(_ item: CensusReview) -> CensusReviewView {
        return CensusReviewView(
            code: item.code,
            nameText: item.name,
            labelText: item.label,
            durationMinutes: String(item.durationMinutes),
            procedureCodeText: item.procedureCode,
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusReviewViews(_ items: [CensusReview]) -> [CensusReviewView] {
        var views: [CensusReviewView] = []
        for item in items {
            views.append(toCensusReviewView(item))
        }
        return views
    }

    static func sumCensusReviewView(_ view: CensusReviewView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedDurationMinutes) + parsedWeight
    }
}
