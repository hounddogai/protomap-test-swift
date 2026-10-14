import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling disclosure agreement is in its life cycle.
    enum RollingDisclosureAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rolling disclosure agreement, with what the planners need to act on it.
    final class RollingDisclosureAgreement {
        var code: String
        var title: String
        var approved: Bool
        var createdAt: Int
        var priority: Int
        var updatedAt: Int
        var status: RollingDisclosureAgreementStatus

        init(code: String, title: String, approved: Bool, createdAt: Int, priority: Int, updatedAt: Int, status: RollingDisclosureAgreementStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.createdAt = createdAt
            self.priority = priority
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RollingDisclosureAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingDisclosureAgreementStatus.validated || next == RollingDisclosureAgreementStatus.published
            case .validated:
                return next == RollingDisclosureAgreementStatus.retired
            case .published:
                return next == RollingDisclosureAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingDisclosureAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling disclosure agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling disclosure agreement") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(priority) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingDisclosureAgreement {
            return RollingDisclosureAgreement(
                code: code,
                title: title,
                approved: approved,
                createdAt: createdAt,
                priority: priority,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling disclosure agreement in status created.
    static func newRollingDisclosureAgreement(_ code: String, title: String) -> RollingDisclosureAgreement {
        return RollingDisclosureAgreement(
            code: code,
            title: title,
            approved: false,
            createdAt: 0,
            priority: 0,
            updatedAt: 0,
            status: RollingDisclosureAgreementStatus.created
        )
    }
}
