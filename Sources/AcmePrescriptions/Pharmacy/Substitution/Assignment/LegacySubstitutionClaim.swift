import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy substitution claim is in its life cycle.
    enum LegacySubstitutionClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy substitution claim and its current status.
    final class LegacySubstitutionClaim {
        var code: String
        var title: String
        var attempts: Int
        var weight: Double
        var graceDays: Int
        var score: Double
        var label: String
        var quantity: Int
        var archived: Bool
        var attributes: [String: String]
        var status: LegacySubstitutionClaimStatus

        init(code: String, title: String, attempts: Int, weight: Double, graceDays: Int, score: Double, label: String, quantity: Int, archived: Bool, attributes: [String: String], status: LegacySubstitutionClaimStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.weight = weight
            self.graceDays = graceDays
            self.score = score
            self.label = label
            self.quantity = quantity
            self.archived = archived
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacySubstitutionClaimStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LegacySubstitutionClaimStatus.cancelled
            case .inProgress:
                return next == LegacySubstitutionClaimStatus.cancelled
            case .completed:
                return next == LegacySubstitutionClaimStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacySubstitutionClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy substitution claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy substitution claim") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveTotal() -> Double {
            return ((Double(quantity) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> LegacySubstitutionClaim {
            return LegacySubstitutionClaim(
                code: code,
                title: title,
                attempts: attempts,
                weight: weight,
                graceDays: graceDays,
                score: score,
                label: label,
                quantity: quantity,
                archived: archived,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy substitution claim in status planned.
    static func newLegacySubstitutionClaim(_ code: String, title: String) -> LegacySubstitutionClaim {
        return LegacySubstitutionClaim(
            code: code,
            title: title,
            attempts: 0,
            weight: 0.0,
            graceDays: 0,
            score: 0.0,
            label: "",
            quantity: 0,
            archived: false,
            attributes: [:],
            status: LegacySubstitutionClaimStatus.planned
        )
    }
}
