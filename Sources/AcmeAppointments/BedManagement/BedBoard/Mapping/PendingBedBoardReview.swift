import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending bed board review is in its life cycle.
    enum PendingBedBoardReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending bed board review. Its code is unique within a tenant.
    final class PendingBedBoardReview {
        var code: String
        var label: String
        var checksum: String
        var quantity: Int
        var batchSize: Int
        var threshold: Double
        var source: String
        var amount: Double
        var active: Bool
        var revision: Int
        var status: PendingBedBoardReviewStatus

        init(code: String, label: String, checksum: String, quantity: Int, batchSize: Int, threshold: Double, source: String, amount: Double, active: Bool, revision: Int, status: PendingBedBoardReviewStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.quantity = quantity
            self.batchSize = batchSize
            self.threshold = threshold
            self.source = source
            self.amount = amount
            self.active = active
            self.revision = revision
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

        func canMoveTo(_ next: PendingBedBoardReviewStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingBedBoardReviewStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: PendingBedBoardReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending bed board review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return (Double(quantity) * threshold * 100).rounded() / 100
        }

        func copyValue() -> PendingBedBoardReview {
            return PendingBedBoardReview(
                code: code,
                label: label,
                checksum: checksum,
                quantity: quantity,
                batchSize: batchSize,
                threshold: threshold,
                source: source,
                amount: amount,
                active: active,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a pending bed board review in status idle.
    static func newPendingBedBoardReview(_ code: String, label: String) -> PendingBedBoardReview {
        return PendingBedBoardReview(
            code: code,
            label: label,
            checksum: "",
            quantity: 0,
            batchSize: 0,
            threshold: 0.0,
            source: "",
            amount: 0.0,
            active: false,
            revision: 0,
            status: PendingBedBoardReviewStatus.idle
        )
    }
}
