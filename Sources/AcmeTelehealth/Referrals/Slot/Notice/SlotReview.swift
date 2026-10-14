import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot review is in its life cycle.
    enum SlotReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A slot review. Its code is unique within a tenant.
    final class SlotReview {
        var code: String
        var name: String
        var ward: String
        var threshold: Double
        var amount: Double
        var status: SlotReviewStatus

        init(code: String, name: String, ward: String, threshold: Double, amount: Double, status: SlotReviewStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.threshold = threshold
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == SlotReviewStatus.queued || next == SlotReviewStatus.running
            case .queued:
                return next == SlotReviewStatus.running || next == SlotReviewStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SlotReviewStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedValue() -> Double {
            return ((threshold + amount) * 100).rounded() / 100
        }

        func copyValue() -> SlotReview {
            return SlotReview(
                code: code,
                name: name,
                ward: ward,
                threshold: threshold,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a slot review in status new.
    static func newSlotReview(_ code: String, name: String) -> SlotReview {
        return SlotReview(
            code: code,
            name: name,
            ward: "",
            threshold: 0.0,
            amount: 0.0,
            status: SlotReviewStatus.new
        )
    }
}
