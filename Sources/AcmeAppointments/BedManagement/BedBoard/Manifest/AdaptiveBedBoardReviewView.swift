import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive bed board review.
    final class AdaptiveBedBoardReviewView {
        var codeText: String
        var name: String
        var limit: String
        var unitText: String
        var ratio: String
        var allergyText: String
        var statusLabel: String

        init(codeText: String, name: String, limit: String, unitText: String, ratio: String, allergyText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.limit = limit
            self.unitText = unitText
            self.ratio = ratio
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveBedBoardReviewView(_ item: AdaptiveBedBoardReview) -> AdaptiveBedBoardReviewView {
        return AdaptiveBedBoardReviewView(
            codeText: item.code,
            name: item.name,
            limit: String(item.limit),
            unitText: item.unit,
            ratio: String(format: "%.2f", item.ratio),
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveBedBoardReviewViews(_ items: [AdaptiveBedBoardReview]) -> [AdaptiveBedBoardReviewView] {
        var views: [AdaptiveBedBoardReviewView] = []
        for item in items {
            views.append(toAdaptiveBedBoardReviewView(item))
        }
        return views
    }

    static func sumAdaptiveBedBoardReviewView(_ view: AdaptiveBedBoardReviewView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedLimit) + parsedRatio
    }
}
