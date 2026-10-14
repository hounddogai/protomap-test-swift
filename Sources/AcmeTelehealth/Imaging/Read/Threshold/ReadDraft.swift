import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read draft is in its life cycle.
    enum ReadDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One read draft, with what the planners need to act on it.
    final class ReadDraft {
        var code: String
        var label: String
        var updatedAt: Int
        var name: String
        var externalRef: String
        var title: String
        var status: ReadDraftStatus

        init(code: String, label: String, updatedAt: Int, name: String, externalRef: String, title: String, status: ReadDraftStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.name = name
            self.externalRef = externalRef
            self.title = title
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

        func canMoveTo(_ next: ReadDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ReadDraftStatus.approved
            case .approved:
                return next == ReadDraftStatus.rejected || next == ReadDraftStatus.withdrawn
            case .rejected:
                return next == ReadDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> ReadDraft {
            return ReadDraft(
                code: code,
                label: label,
                updatedAt: updatedAt,
                name: name,
                externalRef: externalRef,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read draft in status proposed.
    static func newReadDraft(_ code: String, label: String) -> ReadDraft {
        return ReadDraft(
            code: code,
            label: label,
            updatedAt: 0,
            name: "",
            externalRef: "",
            title: "",
            status: ReadDraftStatus.proposed
        )
    }
}
