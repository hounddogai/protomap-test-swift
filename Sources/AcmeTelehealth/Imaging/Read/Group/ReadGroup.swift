import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read group is in its life cycle.
    enum ReadGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A read group as the read team keeps it.
    final class ReadGroup {
        var code: String
        var name: String
        var contactEmail: String
        var copay: Double
        var notes: String
        var status: ReadGroupStatus

        init(code: String, name: String, contactEmail: String, copay: Double, notes: String, status: ReadGroupStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.copay = copay
            self.notes = notes
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

        func canMoveTo(_ next: ReadGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ReadGroupStatus.approved || next == ReadGroupStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ReadGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> ReadGroup {
            return ReadGroup(
                code: code,
                name: name,
                contactEmail: contactEmail,
                copay: copay,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a read group in status proposed.
    static func newReadGroup(_ code: String, name: String) -> ReadGroup {
        return ReadGroup(
            code: code,
            name: name,
            contactEmail: "",
            copay: 0.0,
            notes: "",
            status: ReadGroupStatus.proposed
        )
    }
}
