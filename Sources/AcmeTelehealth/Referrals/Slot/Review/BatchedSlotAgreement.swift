import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched slot agreement is in its life cycle.
    enum BatchedSlotAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a batched slot agreement and its current status.
    final class BatchedSlotAgreement {
        var code: String
        var title: String
        var refills: Int
        var dosageMg: Double
        var attempts: Int
        var phone: String
        var floorValue: Double
        var segment: String
        var externalRef: String
        var status: BatchedSlotAgreementStatus

        init(code: String, title: String, refills: Int, dosageMg: Double, attempts: Int, phone: String, floorValue: Double, segment: String, externalRef: String, status: BatchedSlotAgreementStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.dosageMg = dosageMg
            self.attempts = attempts
            self.phone = phone
            self.floorValue = floorValue
            self.segment = segment
            self.externalRef = externalRef
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

        func canMoveTo(_ next: BatchedSlotAgreementStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedSlotAgreementStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == BatchedSlotAgreementStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSlotAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched slot agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return ((Double(refills) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSlotAgreement {
            return BatchedSlotAgreement(
                code: code,
                title: title,
                refills: refills,
                dosageMg: dosageMg,
                attempts: attempts,
                phone: phone,
                floorValue: floorValue,
                segment: segment,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched slot agreement in status planned.
    static func newBatchedSlotAgreement(_ code: String, title: String) -> BatchedSlotAgreement {
        return BatchedSlotAgreement(
            code: code,
            title: title,
            refills: 0,
            dosageMg: 0.0,
            attempts: 0,
            phone: "",
            floorValue: 0.0,
            segment: "",
            externalRef: "",
            status: BatchedSlotAgreementStatus.planned
        )
    }
}
