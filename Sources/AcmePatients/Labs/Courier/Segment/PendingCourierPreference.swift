import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending courier preference is in its life cycle.
    enum PendingCourierPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending courier preference as the courier team keeps it.
    final class PendingCourierPreference {
        var code: String
        var label: String
        var description: String
        var expiresAt: Int
        var limit: Int
        var status: PendingCourierPreferenceStatus

        init(code: String, label: String, description: String, expiresAt: Int, limit: Int, status: PendingCourierPreferenceStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.expiresAt = expiresAt
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingCourierPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingCourierPreferenceStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PendingCourierPreferenceStatus.closed
            case .suspended:
                return next == PendingCourierPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCourierPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending courier preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending courier preference") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(expiresAt) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCourierPreference {
            return PendingCourierPreference(
                code: code,
                label: label,
                description: description,
                expiresAt: expiresAt,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending courier preference in status draft.
    static func newPendingCourierPreference(_ code: String, label: String) -> PendingCourierPreference {
        return PendingCourierPreference(
            code: code,
            label: label,
            description: "",
            expiresAt: 0,
            limit: 0,
            status: PendingCourierPreferenceStatus.draft
        )
    }
}
