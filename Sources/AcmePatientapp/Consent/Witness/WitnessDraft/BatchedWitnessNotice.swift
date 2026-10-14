import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched witness notice is in its life cycle.
    enum BatchedWitnessNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One batched witness notice, with what the planners need to act on it.
    final class BatchedWitnessNotice {
        var code: String
        var label: String
        var revision: Int
        var discount: Double
        var quantity: Int
        var status: BatchedWitnessNoticeStatus

        init(code: String, label: String, revision: Int, discount: Double, quantity: Int, status: BatchedWitnessNoticeStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.discount = discount
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedWitnessNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == BatchedWitnessNoticeStatus.resolved || next == BatchedWitnessNoticeStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: BatchedWitnessNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched witness notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netVolume() -> Double {
            return ((discount + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedWitnessNotice {
            return BatchedWitnessNotice(
                code: code,
                label: label,
                revision: revision,
                discount: discount,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched witness notice in status open.
    static func newBatchedWitnessNotice(_ code: String, label: String) -> BatchedWitnessNotice {
        return BatchedWitnessNotice(
            code: code,
            label: label,
            revision: 0,
            discount: 0.0,
            quantity: 0,
            status: BatchedWitnessNoticeStatus.`open`
        )
    }
}
