import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback formulary review is in its life cycle.
    enum FallbackFormularyReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One fallback formulary review, with what the planners need to act on it.
    final class FallbackFormularyReview {
        var code: String
        var name: String
        var attributes: [String: String]
        var title: String
        var acuity: Int
        var clinicianID: String
        var budget: Double
        var batchSize: Int
        var maximum: Double
        var amount: Double
        var status: FallbackFormularyReviewStatus

        init(code: String, name: String, attributes: [String: String], title: String, acuity: Int, clinicianID: String, budget: Double, batchSize: Int, maximum: Double, amount: Double, status: FallbackFormularyReviewStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.title = title
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.budget = budget
            self.batchSize = batchSize
            self.maximum = maximum
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackFormularyReviewStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FallbackFormularyReviewStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackFormularyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback formulary review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func effectiveLoad() -> Double {
            return (maximum * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFormularyReview {
            return FallbackFormularyReview(
                code: code,
                name: name,
                attributes: attributes,
                title: title,
                acuity: acuity,
                clinicianID: clinicianID,
                budget: budget,
                batchSize: batchSize,
                maximum: maximum,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback formulary review in status proposed.
    static func newFallbackFormularyReview(_ code: String, name: String) -> FallbackFormularyReview {
        return FallbackFormularyReview(
            code: code,
            name: name,
            attributes: [:],
            title: "",
            acuity: 0,
            clinicianID: "",
            budget: 0.0,
            batchSize: 0,
            maximum: 0.0,
            amount: 0.0,
            status: FallbackFormularyReviewStatus.proposed
        )
    }
}
