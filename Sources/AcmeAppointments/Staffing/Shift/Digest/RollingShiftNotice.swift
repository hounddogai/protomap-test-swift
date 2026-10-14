import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling shift notice is in its life cycle.
    enum RollingShiftNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling shift notice as the shift team keeps it.
    final class RollingShiftNotice {
        var code: String
        var label: String
        var reviewer: String
        var updatedAt: Int
        var summary: String
        var expiresAt: Int
        var status: RollingShiftNoticeStatus

        init(code: String, label: String, reviewer: String, updatedAt: Int, summary: String, expiresAt: Int, status: RollingShiftNoticeStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.updatedAt = updatedAt
            self.summary = summary
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RollingShiftNoticeStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingShiftNoticeStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingShiftNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling shift notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return ((Double(expiresAt) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingShiftNotice {
            return RollingShiftNotice(
                code: code,
                label: label,
                reviewer: reviewer,
                updatedAt: updatedAt,
                summary: summary,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling shift notice in status created.
    static func newRollingShiftNotice(_ code: String, label: String) -> RollingShiftNotice {
        return RollingShiftNotice(
            code: code,
            label: label,
            reviewer: "",
            updatedAt: 0,
            summary: "",
            expiresAt: 0,
            status: RollingShiftNoticeStatus.created
        )
    }
}
