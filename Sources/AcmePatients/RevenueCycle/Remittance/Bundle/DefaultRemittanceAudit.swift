import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default remittance audit is in its life cycle.
    enum DefaultRemittanceAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One default remittance audit, with what the planners need to act on it.
    final class DefaultRemittanceAudit {
        var code: String
        var title: String
        var visitMinutes: Int
        var floorValue: Double
        var visible: Bool
        var status: DefaultRemittanceAuditStatus

        init(code: String, title: String, visitMinutes: Int, floorValue: Double, visible: Bool, status: DefaultRemittanceAuditStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.floorValue = floorValue
            self.visible = visible
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

        func canMoveTo(_ next: DefaultRemittanceAuditStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultRemittanceAuditStatus.rejected || next == DefaultRemittanceAuditStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultRemittanceAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default remittance audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveVolume() -> Double {
            return ((floorValue - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRemittanceAudit {
            return DefaultRemittanceAudit(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                floorValue: floorValue,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default remittance audit in status proposed.
    static func newDefaultRemittanceAudit(_ code: String, title: String) -> DefaultRemittanceAudit {
        return DefaultRemittanceAudit(
            code: code,
            title: title,
            visitMinutes: 0,
            floorValue: 0.0,
            visible: false,
            status: DefaultRemittanceAuditStatus.proposed
        )
    }
}
