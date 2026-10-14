import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a batched credential review.
    final class BatchedCredentialReviewView {
        var codeText: String
        var label: String
        var dosageMgText: String
        var ceilingText: String
        var sequence: String
        var updatedAt: String
        var createdAt: String
        var externalRef: String
        var phone: String
        var expiresAtText: String
        var statusLabel: String

        init(codeText: String, label: String, dosageMgText: String, ceilingText: String, sequence: String, updatedAt: String, createdAt: String, externalRef: String, phone: String, expiresAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.dosageMgText = dosageMgText
            self.ceilingText = ceilingText
            self.sequence = sequence
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.phone = phone
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCredentialReviewView(_ item: BatchedCredentialReview) -> BatchedCredentialReviewView {
        return BatchedCredentialReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 120),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            ceilingText: String(format: "%.2f", item.ceiling),
            sequence: String(item.sequence),
            updatedAt: String(item.updatedAt),
            createdAt: String(item.createdAt),
            externalRef: item.externalRef,
            phone: item.phone,
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCredentialReviewViews(_ items: [BatchedCredentialReview]) -> [BatchedCredentialReviewView] {
        var views: [BatchedCredentialReviewView] = []
        for item in items {
            views.append(toBatchedCredentialReviewView(item))
        }
        return views
    }

    static func sumBatchedCredentialReviewView(_ view: BatchedCredentialReviewView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedDosageMg + parsedCeiling + Double(parsedSequence)
    }
}
