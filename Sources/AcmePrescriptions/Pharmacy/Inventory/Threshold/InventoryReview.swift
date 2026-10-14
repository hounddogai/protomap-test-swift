import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory review is in its life cycle.
    enum InventoryReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A inventory review. Its code is unique within a tenant.
    final class InventoryReview {
        var code: String
        var name: String
        var channel: String
        var batchSize: Int
        var attempts: Int
        var timezone: String
        var currency: String
        var status: InventoryReviewStatus

        init(code: String, name: String, channel: String, batchSize: Int, attempts: Int, timezone: String, currency: String, status: InventoryReviewStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.batchSize = batchSize
            self.attempts = attempts
            self.timezone = timezone
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryReviewStatus) -> Bool {
            switch status {
            case .created:
                return next == InventoryReviewStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: InventoryReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return (Double(attempts) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> InventoryReview {
            return InventoryReview(
                code: code,
                name: name,
                channel: channel,
                batchSize: batchSize,
                attempts: attempts,
                timezone: timezone,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a inventory review in status created.
    static func newInventoryReview(_ code: String, name: String) -> InventoryReview {
        return InventoryReview(
            code: code,
            name: name,
            channel: "",
            batchSize: 0,
            attempts: 0,
            timezone: "",
            currency: "",
            status: InventoryReviewStatus.created
        )
    }
}
