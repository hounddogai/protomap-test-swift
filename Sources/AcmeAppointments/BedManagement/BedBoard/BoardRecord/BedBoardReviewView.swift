import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board review.
    final class BedBoardReviewView {
        var code: String
        var name: String
        var versionText: String
        var attemptsText: String
        var amountText: String
        var margin: String
        var approved: String
        var diagnosisCode: String
        var createdAt: String
        var quantityText: String
        var description: String
        var statusLabel: String

        init(code: String, name: String, versionText: String, attemptsText: String, amountText: String, margin: String, approved: String, diagnosisCode: String, createdAt: String, quantityText: String, description: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.versionText = versionText
            self.attemptsText = attemptsText
            self.amountText = amountText
            self.margin = margin
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.quantityText = quantityText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardReviewView(_ item: BedBoardReview) -> BedBoardReviewView {
        return BedBoardReviewView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            versionText: String(item.version),
            attemptsText: String(item.attempts),
            amountText: String(format: "%.2f", item.amount),
            margin: String(format: "%.2f", item.margin),
            approved: "\(item.approved)",
            diagnosisCode: item.diagnosisCode,
            createdAt: String(item.createdAt),
            quantityText: String(item.quantity),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardReviewViews(_ items: [BedBoardReview]) -> [BedBoardReviewView] {
        var views: [BedBoardReviewView] = []
        for item in items {
            views.append(toBedBoardReviewView(item))
        }
        return views
    }

    static func sumBedBoardReviewView(_ view: BedBoardReviewView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedVersion) + Double(parsedAttempts) + parsedAmount
    }
}
