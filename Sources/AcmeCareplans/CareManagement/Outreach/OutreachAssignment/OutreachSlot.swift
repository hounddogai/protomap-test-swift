import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach slot is in its life cycle.
    enum OutreachSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A outreach slot as the outreach team keeps it.
    final class OutreachSlot {
        var code: String
        var name: String
        var procedureCode: String
        var checksum: String
        var visitMinutes: Int
        var status: OutreachSlotStatus

        init(code: String, name: String, procedureCode: String, checksum: String, visitMinutes: Int, status: OutreachSlotStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachSlotStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == OutreachSlotStatus.revoked || next == OutreachSlotStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: OutreachSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> OutreachSlot {
            return OutreachSlot(
                code: code,
                name: name,
                procedureCode: procedureCode,
                checksum: checksum,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a outreach slot in status requested.
    static func newOutreachSlot(_ code: String, name: String) -> OutreachSlot {
        return OutreachSlot(
            code: code,
            name: name,
            procedureCode: "",
            checksum: "",
            visitMinutes: 0,
            status: OutreachSlotStatus.requested
        )
    }
}
