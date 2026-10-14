import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool review is in its life cycle.
    enum FloatPoolReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a float pool review and its current status.
    final class FloatPoolReview {
        var code: String
        var title: String
        var rate: Double
        var budget: Double
        var updatedAt: Int
        var allergy: String
        var startsAt: Int
        var ratio: Double
        var status: FloatPoolReviewStatus

        init(code: String, title: String, rate: Double, budget: Double, updatedAt: Int, allergy: String, startsAt: Int, ratio: Double, status: FloatPoolReviewStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.budget = budget
            self.updatedAt = updatedAt
            self.allergy = allergy
            self.startsAt = startsAt
            self.ratio = ratio
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

        func canMoveTo(_ next: FloatPoolReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FloatPoolReviewStatus.approved || next == FloatPoolReviewStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FloatPoolReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return ((rate + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolReview {
            return FloatPoolReview(
                code: code,
                title: title,
                rate: rate,
                budget: budget,
                updatedAt: updatedAt,
                allergy: allergy,
                startsAt: startsAt,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a float pool review in status proposed.
    static func newFloatPoolReview(_ code: String, title: String) -> FloatPoolReview {
        return FloatPoolReview(
            code: code,
            title: title,
            rate: 0.0,
            budget: 0.0,
            updatedAt: 0,
            allergy: "",
            startsAt: 0,
            ratio: 0.0,
            status: FloatPoolReviewStatus.proposed
        )
    }
}
