import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default charge review is in its life cycle.
    enum DefaultChargeReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default charge review. Its code is unique within a tenant.
    final class DefaultChargeReview {
        var code: String
        var label: String
        var ownerID: String
        var rate: Double
        var ward: String
        var status: DefaultChargeReviewStatus

        init(code: String, label: String, ownerID: String, rate: Double, ward: String, status: DefaultChargeReviewStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.rate = rate
            self.ward = ward
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

        func canMoveTo(_ next: DefaultChargeReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultChargeReviewStatus.warming
            case .warming:
                return next == DefaultChargeReviewStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultChargeReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultChargeReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default charge review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> DefaultChargeReview {
            return DefaultChargeReview(
                code: code,
                label: label,
                ownerID: ownerID,
                rate: rate,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default charge review in status idle.
    static func newDefaultChargeReview(_ code: String, label: String) -> DefaultChargeReview {
        return DefaultChargeReview(
            code: code,
            label: label,
            ownerID: "",
            rate: 0.0,
            ward: "",
            status: DefaultChargeReviewStatus.idle
        )
    }
}
