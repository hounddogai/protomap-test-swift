import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation preference is in its life cycle.
    enum RevocationPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a revocation preference and its current status.
    final class RevocationPreference {
        var code: String
        var title: String
        var visitMinutes: Int
        var copay: Double
        var approved: Bool
        var notes: String
        var status: RevocationPreferenceStatus

        init(code: String, title: String, visitMinutes: Int, copay: Double, approved: Bool, notes: String, status: RevocationPreferenceStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.approved = approved
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RevocationPreferenceStatus.completed
            case .inProgress:
                return next == RevocationPreferenceStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RevocationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedLoad() -> Double {
            return ((copay - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationPreference {
            return RevocationPreference(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                copay: copay,
                approved: approved,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation preference in status planned.
    static func newRevocationPreference(_ code: String, title: String) -> RevocationPreference {
        return RevocationPreference(
            code: code,
            title: title,
            visitMinutes: 0,
            copay: 0.0,
            approved: false,
            notes: "",
            status: RevocationPreferenceStatus.planned
        )
    }
}
