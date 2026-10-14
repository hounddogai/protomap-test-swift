import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy request is in its life cycle.
    enum ProxyRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One proxy request, with what the planners need to act on it.
    final class ProxyRequest {
        var code: String
        var title: String
        var amount: Double
        var acuity: Int
        var priority: Int
        var facility: String
        var archived: Bool
        var status: ProxyRequestStatus

        init(code: String, title: String, amount: Double, acuity: Int, priority: Int, facility: String, archived: Bool, status: ProxyRequestStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.acuity = acuity
            self.priority = priority
            self.facility = facility
            self.archived = archived
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

        func canMoveTo(_ next: ProxyRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProxyRequestStatus.pending || next == ProxyRequestStatus.suspended
            case .pending:
                return next == ProxyRequestStatus.closed
            case .active:
                return next == ProxyRequestStatus.suspended || next == ProxyRequestStatus.closed
            case .suspended:
                return next == ProxyRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("proxy request") \(code)"
        }

        func projectedTotal() -> Double {
            return ((amount - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyRequest {
            return ProxyRequest(
                code: code,
                title: title,
                amount: amount,
                acuity: acuity,
                priority: priority,
                facility: facility,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy request in status draft.
    static func newProxyRequest(_ code: String, title: String) -> ProxyRequest {
        return ProxyRequest(
            code: code,
            title: title,
            amount: 0.0,
            acuity: 0,
            priority: 0,
            facility: "",
            archived: false,
            status: ProxyRequestStatus.draft
        )
    }
}
