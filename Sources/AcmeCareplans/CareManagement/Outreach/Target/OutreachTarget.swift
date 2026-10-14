import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach target is in its life cycle.
    enum OutreachTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a outreach target and its current status.
    final class OutreachTarget {
        var code: String
        var title: String
        var retries: Int
        var acuity: Int
        var timezone: String
        var checksum: String
        var status: OutreachTargetStatus

        init(code: String, title: String, retries: Int, acuity: Int, timezone: String, checksum: String, status: OutreachTargetStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.acuity = acuity
            self.timezone = timezone
            self.checksum = checksum
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

        func canMoveTo(_ next: OutreachTargetStatus) -> Bool {
            switch status {
            case .requested:
                return next == OutreachTargetStatus.revoked || next == OutreachTargetStatus.expired
            case .granted:
                return next == OutreachTargetStatus.revoked || next == OutreachTargetStatus.expired
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

        func moveTo(_ next: OutreachTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("outreach target") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(retries) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachTarget {
            return OutreachTarget(
                code: code,
                title: title,
                retries: retries,
                acuity: acuity,
                timezone: timezone,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach target in status requested.
    static func newOutreachTarget(_ code: String, title: String) -> OutreachTarget {
        return OutreachTarget(
            code: code,
            title: title,
            retries: 0,
            acuity: 0,
            timezone: "",
            checksum: "",
            status: OutreachTargetStatus.requested
        )
    }
}
