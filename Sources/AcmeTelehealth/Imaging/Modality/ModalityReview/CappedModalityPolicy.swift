import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped modality policy is in its life cycle.
    enum CappedModalityPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped modality policy as the modality team keeps it.
    final class CappedModalityPolicy {
        var code: String
        var label: String
        var timezone: String
        var ward: String
        var capacity: Int
        var copay: Double
        var threshold: Double
        var cost: Double
        var status: CappedModalityPolicyStatus

        init(code: String, label: String, timezone: String, ward: String, capacity: Int, copay: Double, threshold: Double, cost: Double, status: CappedModalityPolicyStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.ward = ward
            self.capacity = capacity
            self.copay = copay
            self.threshold = threshold
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedModalityPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedModalityPolicyStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CappedModalityPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped modality policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return ((copay + cost) * 100).rounded() / 100
        }

        func copyValue() -> CappedModalityPolicy {
            return CappedModalityPolicy(
                code: code,
                label: label,
                timezone: timezone,
                ward: ward,
                capacity: capacity,
                copay: copay,
                threshold: threshold,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped modality policy in status draft.
    static func newCappedModalityPolicy(_ code: String, label: String) -> CappedModalityPolicy {
        return CappedModalityPolicy(
            code: code,
            label: label,
            timezone: "",
            ward: "",
            capacity: 0,
            copay: 0.0,
            threshold: 0.0,
            cost: 0.0,
            status: CappedModalityPolicyStatus.draft
        )
    }
}
