import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped statement threshold is in its life cycle.
    enum CappedStatementThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One capped statement threshold, with what the planners need to act on it.
    final class CappedStatementThreshold {
        var code: String
        var label: String
        var rate: Double
        var checksum: String
        var discount: Double
        var bed: String
        var status: CappedStatementThresholdStatus

        init(code: String, label: String, rate: Double, checksum: String, discount: Double, bed: String, status: CappedStatementThresholdStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.checksum = checksum
            self.discount = discount
            self.bed = bed
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

        func canMoveTo(_ next: CappedStatementThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CappedStatementThresholdStatus.withdrawn
            case .rejected:
                return next == CappedStatementThresholdStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedStatementThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped statement threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped statement threshold") \(code)"
        }

        func netExposure() -> Double {
            return (rate * discount * 100).rounded() / 100
        }

        func copyValue() -> CappedStatementThreshold {
            return CappedStatementThreshold(
                code: code,
                label: label,
                rate: rate,
                checksum: checksum,
                discount: discount,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped statement threshold in status proposed.
    static func newCappedStatementThreshold(_ code: String, label: String) -> CappedStatementThreshold {
        return CappedStatementThreshold(
            code: code,
            label: label,
            rate: 0.0,
            checksum: "",
            discount: 0.0,
            bed: "",
            status: CappedStatementThresholdStatus.proposed
        )
    }
}
