import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel audit is in its life cycle.
    enum PanelAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a panel audit and its current status.
    final class PanelAudit {
        var code: String
        var name: String
        var phone: String
        var acuity: Int
        var endsAt: Int
        var archived: Bool
        var copay: Double
        var status: PanelAuditStatus

        init(code: String, name: String, phone: String, acuity: Int, endsAt: Int, archived: Bool, copay: Double, status: PanelAuditStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.acuity = acuity
            self.endsAt = endsAt
            self.archived = archived
            self.copay = copay
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

        func canMoveTo(_ next: PanelAuditStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PanelAuditStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(acuity) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PanelAudit {
            return PanelAudit(
                code: code,
                name: name,
                phone: phone,
                acuity: acuity,
                endsAt: endsAt,
                archived: archived,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a panel audit in status proposed.
    static func newPanelAudit(_ code: String, name: String) -> PanelAudit {
        return PanelAudit(
            code: code,
            name: name,
            phone: "",
            acuity: 0,
            endsAt: 0,
            archived: false,
            copay: 0.0,
            status: PanelAuditStatus.proposed
        )
    }
}
