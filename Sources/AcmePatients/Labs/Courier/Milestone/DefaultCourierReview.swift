import AcmePlatform
import Foundation

extension Labs {
    /// Where a default courier review is in its life cycle.
    enum DefaultCourierReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default courier review and its current status.
    final class DefaultCourierReview {
        var code: String
        var title: String
        var region: String
        var allergy: String
        var procedureCode: String
        var quantity: Int
        var status: DefaultCourierReviewStatus

        init(code: String, title: String, region: String, allergy: String, procedureCode: String, quantity: Int, status: DefaultCourierReviewStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.allergy = allergy
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultCourierReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultCourierReviewStatus.draining || next == DefaultCourierReviewStatus.stopped
            case .warming:
                return next == DefaultCourierReviewStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultCourierReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default courier review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default courier review") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> DefaultCourierReview {
            return DefaultCourierReview(
                code: code,
                title: title,
                region: region,
                allergy: allergy,
                procedureCode: procedureCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default courier review in status idle.
    static func newDefaultCourierReview(_ code: String, title: String) -> DefaultCourierReview {
        return DefaultCourierReview(
            code: code,
            title: title,
            region: "",
            allergy: "",
            procedureCode: "",
            quantity: 0,
            status: DefaultCourierReviewStatus.idle
        )
    }
}
