import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped closure request is in its life cycle.
    enum CappedClosureRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped closure request, with what the planners need to act on it.
    final class CappedClosureRequest {
        var code: String
        var title: String
        var contactEmail: String
        var currency: String
        var rate: Double
        var specialty: String
        var copay: Double
        var status: CappedClosureRequestStatus

        init(code: String, title: String, contactEmail: String, currency: String, rate: Double, specialty: String, copay: Double, status: CappedClosureRequestStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.currency = currency
            self.rate = rate
            self.specialty = specialty
            self.copay = copay
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

        func canMoveTo(_ next: CappedClosureRequestStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedClosureRequestStatus.scheduled || next == CappedClosureRequestStatus.completed
            case .scheduled:
                return next == CappedClosureRequestStatus.cancelled
            case .inProgress:
                return next == CappedClosureRequestStatus.completed
            case .completed:
                return next == CappedClosureRequestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedClosureRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped closure request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return ((copay - rate) * 100).rounded() / 100
        }

        func copyValue() -> CappedClosureRequest {
            return CappedClosureRequest(
                code: code,
                title: title,
                contactEmail: contactEmail,
                currency: currency,
                rate: rate,
                specialty: specialty,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped closure request in status planned.
    static func newCappedClosureRequest(_ code: String, title: String) -> CappedClosureRequest {
        return CappedClosureRequest(
            code: code,
            title: title,
            contactEmail: "",
            currency: "",
            rate: 0.0,
            specialty: "",
            copay: 0.0,
            status: CappedClosureRequestStatus.planned
        )
    }
}
