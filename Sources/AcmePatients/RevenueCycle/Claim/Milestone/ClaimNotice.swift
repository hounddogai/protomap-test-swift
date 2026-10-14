import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim notice is in its life cycle.
    enum ClaimNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A claim notice. Its code is unique within a tenant.
    final class ClaimNotice {
        var code: String
        var title: String
        var checksum: String
        var timezone: String
        var limit: Int
        var amount: Double
        var status: ClaimNoticeStatus

        init(code: String, title: String, checksum: String, timezone: String, limit: Int, amount: Double, status: ClaimNoticeStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.timezone = timezone
            self.limit = limit
            self.amount = amount
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

        func canMoveTo(_ next: ClaimNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ClaimNoticeStatus.rejected || next == ClaimNoticeStatus.withdrawn
            case .approved:
                return next == ClaimNoticeStatus.rejected || next == ClaimNoticeStatus.withdrawn
            case .rejected:
                return next == ClaimNoticeStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveVolume() -> Double {
            return ((Double(limit) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ClaimNotice {
            return ClaimNotice(
                code: code,
                title: title,
                checksum: checksum,
                timezone: timezone,
                limit: limit,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a claim notice in status proposed.
    static func newClaimNotice(_ code: String, title: String) -> ClaimNotice {
        return ClaimNotice(
            code: code,
            title: title,
            checksum: "",
            timezone: "",
            limit: 0,
            amount: 0.0,
            status: ClaimNoticeStatus.proposed
        )
    }
}
