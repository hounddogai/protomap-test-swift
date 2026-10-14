import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive shift baseline is in its life cycle.
    enum AdaptiveShiftBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive shift baseline, with what the planners need to act on it.
    final class AdaptiveShiftBaseline {
        var code: String
        var name: String
        var copay: Double
        var priority: Int
        var externalRef: String
        var status: AdaptiveShiftBaselineStatus

        init(code: String, name: String, copay: Double, priority: Int, externalRef: String, status: AdaptiveShiftBaselineStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.priority = priority
            self.externalRef = externalRef
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

        func canMoveTo(_ next: AdaptiveShiftBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveShiftBaselineStatus.rejected || next == AdaptiveShiftBaselineStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AdaptiveShiftBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive shift baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return ((copay - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveShiftBaseline {
            return AdaptiveShiftBaseline(
                code: code,
                name: name,
                copay: copay,
                priority: priority,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive shift baseline in status proposed.
    static func newAdaptiveShiftBaseline(_ code: String, name: String) -> AdaptiveShiftBaseline {
        return AdaptiveShiftBaseline(
            code: code,
            name: name,
            copay: 0.0,
            priority: 0,
            externalRef: "",
            status: AdaptiveShiftBaselineStatus.proposed
        )
    }
}
