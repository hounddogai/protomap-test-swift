import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation review.
    final class RevocationReviewView {
        var codeText: String
        var titleText: String
        var versionText: String
        var budgetText: String
        var diagnosisCodeText: String
        var createdAt: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, titleText: String, versionText: String, budgetText: String, diagnosisCodeText: String, createdAt: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.versionText = versionText
            self.budgetText = budgetText
            self.diagnosisCodeText = diagnosisCodeText
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationReviewView(_ item: RevocationReview) -> RevocationReviewView {
        return RevocationReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            versionText: String(item.version),
            budgetText: String(format: "%.2f", item.budget),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            createdAt: String(item.createdAt),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationReviewViews(_ items: [RevocationReview]) -> [RevocationReviewView] {
        var views: [RevocationReviewView] = []
        for item in items {
            views.append(toRevocationReviewView(item))
        }
        return views
    }

    static func sumRevocationReviewView(_ view: RevocationReviewView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedVersion) + parsedBudget + Double(parsedCreatedAt)
    }
}
