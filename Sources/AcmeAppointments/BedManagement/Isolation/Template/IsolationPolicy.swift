import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation policy is in its life cycle.
    enum IsolationPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A isolation policy as the isolation team keeps it.
    final class IsolationPolicy {
        var code: String
        var label: String
        var category: String
        var facility: String
        var region: String
        var currency: String
        var dosageMg: Double
        var status: IsolationPolicyStatus

        init(code: String, label: String, category: String, facility: String, region: String, currency: String, dosageMg: Double, status: IsolationPolicyStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.facility = facility
            self.region = region
            self.currency = currency
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: IsolationPolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == IsolationPolicyStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == IsolationPolicyStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> IsolationPolicy {
            return IsolationPolicy(
                code: code,
                label: label,
                category: category,
                facility: facility,
                region: region,
                currency: currency,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a isolation policy in status new.
    static func newIsolationPolicy(_ code: String, label: String) -> IsolationPolicy {
        return IsolationPolicy(
            code: code,
            label: label,
            category: "",
            facility: "",
            region: "",
            currency: "",
            dosageMg: 0.0,
            status: IsolationPolicyStatus.new
        )
    }
}
