import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff exception is in its life cycle.
    enum HandoffExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A handoff exception as the handoff team keeps it.
    final class HandoffException {
        var code: String
        var title: String
        var expiresAt: Int
        var approved: Bool
        var capacity: Int
        var status: HandoffExceptionStatus

        init(code: String, title: String, expiresAt: Int, approved: Bool, capacity: Int, status: HandoffExceptionStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.approved = approved
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: HandoffExceptionStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == HandoffExceptionStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: HandoffExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return (Double(expiresAt) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> HandoffException {
            return HandoffException(
                code: code,
                title: title,
                expiresAt: expiresAt,
                approved: approved,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff exception in status created.
    static func newHandoffException(_ code: String, title: String) -> HandoffException {
        return HandoffException(
            code: code,
            title: title,
            expiresAt: 0,
            approved: false,
            capacity: 0,
            status: HandoffExceptionStatus.created
        )
    }
}
