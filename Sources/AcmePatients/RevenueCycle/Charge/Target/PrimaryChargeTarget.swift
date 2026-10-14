import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary charge target is in its life cycle.
    enum PrimaryChargeTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary charge target as the charge team keeps it.
    final class PrimaryChargeTarget {
        var code: String
        var name: String
        var visible: Bool
        var maximum: Double
        var channel: String
        var procedureCode: String
        var status: PrimaryChargeTargetStatus

        init(code: String, name: String, visible: Bool, maximum: Double, channel: String, procedureCode: String, status: PrimaryChargeTargetStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.maximum = maximum
            self.channel = channel
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: PrimaryChargeTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryChargeTargetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryChargeTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary charge target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> PrimaryChargeTarget {
            return PrimaryChargeTarget(
                code: code,
                name: name,
                visible: visible,
                maximum: maximum,
                channel: channel,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary charge target in status proposed.
    static func newPrimaryChargeTarget(_ code: String, name: String) -> PrimaryChargeTarget {
        return PrimaryChargeTarget(
            code: code,
            name: name,
            visible: false,
            maximum: 0.0,
            channel: "",
            procedureCode: "",
            status: PrimaryChargeTargetStatus.proposed
        )
    }
}
