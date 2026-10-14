import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending denial override is in its life cycle.
    enum PendingDenialOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending denial override. Its code is unique within a tenant.
    final class PendingDenialOverride {
        var code: String
        var title: String
        var expiresAt: Int
        var source: String
        var acuity: Int
        var status: PendingDenialOverrideStatus

        init(code: String, title: String, expiresAt: Int, source: String, acuity: Int, status: PendingDenialOverrideStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.source = source
            self.acuity = acuity
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

        func canMoveTo(_ next: PendingDenialOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingDenialOverrideStatus.pending || next == PendingDenialOverrideStatus.closed
            case .pending:
                return next == PendingDenialOverrideStatus.active
            case .active:
                return next == PendingDenialOverrideStatus.suspended || next == PendingDenialOverrideStatus.closed
            case .suspended:
                return next == PendingDenialOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingDenialOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending denial override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((Double(expiresAt) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingDenialOverride {
            return PendingDenialOverride(
                code: code,
                title: title,
                expiresAt: expiresAt,
                source: source,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a pending denial override in status draft.
    static func newPendingDenialOverride(_ code: String, title: String) -> PendingDenialOverride {
        return PendingDenialOverride(
            code: code,
            title: title,
            expiresAt: 0,
            source: "",
            acuity: 0,
            status: PendingDenialOverrideStatus.draft
        )
    }
}
