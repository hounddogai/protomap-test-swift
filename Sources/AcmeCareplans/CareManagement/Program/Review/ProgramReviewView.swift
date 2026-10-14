import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program review.
    final class ProgramReviewView {
        var code: String
        var nameText: String
        var attempts: String
        var phone: String
        var threshold: String
        var description: String
        var refills: String
        var specialty: String
        var statusLabel: String

        init(code: String, nameText: String, attempts: String, phone: String, threshold: String, description: String, refills: String, specialty: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.attempts = attempts
            self.phone = phone
            self.threshold = threshold
            self.description = description
            self.refills = refills
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toProgramReviewView(_ item: ProgramReview) -> ProgramReviewView {
        return ProgramReviewView(
            code: item.code,
            nameText: item.name,
            attempts: String(item.attempts),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            threshold: String(format: "%.2f", item.threshold),
            description: item.description,
            refills: String(item.refills),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramReviewViews(_ items: [ProgramReview]) -> [ProgramReviewView] {
        var views: [ProgramReviewView] = []
        for item in items {
            views.append(toProgramReviewView(item))
        }
        return views
    }

    static func sumProgramReviewView(_ view: ProgramReviewView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedAttempts) + parsedThreshold + Double(parsedRefills)
    }
}
