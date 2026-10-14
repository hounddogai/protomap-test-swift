import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist audit is in its life cycle.
    enum WorklistAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A worklist audit as the worklist team keeps it.
    final class WorklistAudit {
        var code: String
        var title: String
        var sequence: Int
        var approved: Bool
        var quantity: Int
        var status: WorklistAuditStatus

        init(code: String, title: String, sequence: Int, approved: Bool, quantity: Int, status: WorklistAuditStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.approved = approved
            self.quantity = quantity
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

        func canMoveTo(_ next: WorklistAuditStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WorklistAuditStatus.expired
            case .revoked:
                return next == WorklistAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("worklist audit") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(quantity) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistAudit {
            return WorklistAudit(
                code: code,
                title: title,
                sequence: sequence,
                approved: approved,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist audit in status requested.
    static func newWorklistAudit(_ code: String, title: String) -> WorklistAudit {
        return WorklistAudit(
            code: code,
            title: title,
            sequence: 0,
            approved: false,
            quantity: 0,
            status: WorklistAuditStatus.requested
        )
    }
}
