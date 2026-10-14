import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation preference is in its life cycle.
    enum IsolationPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A isolation preference. Its code is unique within a tenant.
    final class IsolationPreference {
        var code: String
        var label: String
        var rate: Double
        var unit: String
        var copay: Double
        var timezone: String
        var status: IsolationPreferenceStatus

        init(code: String, label: String, rate: Double, unit: String, copay: Double, timezone: String, status: IsolationPreferenceStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.unit = unit
            self.copay = copay
            self.timezone = timezone
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

        func canMoveTo(_ next: IsolationPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == IsolationPreferenceStatus.ready || next == IsolationPreferenceStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == IsolationPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return (rate * copay * 100).rounded() / 100
        }

        func copyValue() -> IsolationPreference {
            return IsolationPreference(
                code: code,
                label: label,
                rate: rate,
                unit: unit,
                copay: copay,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a isolation preference in status idle.
    static func newIsolationPreference(_ code: String, label: String) -> IsolationPreference {
        return IsolationPreference(
            code: code,
            label: label,
            rate: 0.0,
            unit: "",
            copay: 0.0,
            timezone: "",
            status: IsolationPreferenceStatus.idle
        )
    }
}
