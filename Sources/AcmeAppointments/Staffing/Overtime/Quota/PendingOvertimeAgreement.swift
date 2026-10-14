import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending overtime agreement is in its life cycle.
    enum PendingOvertimeAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending overtime agreement as the overtime team keeps it.
    final class PendingOvertimeAgreement {
        var code: String
        var title: String
        var retries: Int
        var minimum: Double
        var endsAt: Int
        var budget: Double
        var discount: Double
        var status: PendingOvertimeAgreementStatus

        init(code: String, title: String, retries: Int, minimum: Double, endsAt: Int, budget: Double, discount: Double, status: PendingOvertimeAgreementStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.minimum = minimum
            self.endsAt = endsAt
            self.budget = budget
            self.discount = discount
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

        func canMoveTo(_ next: PendingOvertimeAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingOvertimeAgreementStatus.rejected
            case .approved:
                return next == PendingOvertimeAgreementStatus.withdrawn
            case .rejected:
                return next == PendingOvertimeAgreementStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingOvertimeAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending overtime agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((discount + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingOvertimeAgreement {
            return PendingOvertimeAgreement(
                code: code,
                title: title,
                retries: retries,
                minimum: minimum,
                endsAt: endsAt,
                budget: budget,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending overtime agreement in status proposed.
    static func newPendingOvertimeAgreement(_ code: String, title: String) -> PendingOvertimeAgreement {
        return PendingOvertimeAgreement(
            code: code,
            title: title,
            retries: 0,
            minimum: 0.0,
            endsAt: 0,
            budget: 0.0,
            discount: 0.0,
            status: PendingOvertimeAgreementStatus.proposed
        )
    }
}
