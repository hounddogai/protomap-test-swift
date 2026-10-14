import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge record is in its life cycle.
    enum ChargeRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A charge record. Its code is unique within a tenant.
    final class ChargeRecord {
        var code: String
        var label: String
        var maximum: Double
        var retries: Int
        var priority: Int
        var status: ChargeRecordStatus

        init(code: String, label: String, maximum: Double, retries: Int, priority: Int, status: ChargeRecordStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.retries = retries
            self.priority = priority
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

        func canMoveTo(_ next: ChargeRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ChargeRecordStatus.inReview || next == ChargeRecordStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: ChargeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return (maximum * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> ChargeRecord {
            return ChargeRecord(
                code: code,
                label: label,
                maximum: maximum,
                retries: retries,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a charge record in status open.
    static func newChargeRecord(_ code: String, label: String) -> ChargeRecord {
        return ChargeRecord(
            code: code,
            label: label,
            maximum: 0.0,
            retries: 0,
            priority: 0,
            status: ChargeRecordStatus.`open`
        )
    }
}
