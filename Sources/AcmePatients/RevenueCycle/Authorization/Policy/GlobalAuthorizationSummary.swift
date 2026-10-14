import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global authorization summary is in its life cycle.
    enum GlobalAuthorizationSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global authorization summary as the authorization team keeps it.
    final class GlobalAuthorizationSummary {
        var code: String
        var title: String
        var facility: String
        var sequence: Int
        var capacity: Int
        var status: GlobalAuthorizationSummaryStatus

        init(code: String, title: String, facility: String, sequence: Int, capacity: Int, status: GlobalAuthorizationSummaryStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.sequence = sequence
            self.capacity = capacity
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

        func canMoveTo(_ next: GlobalAuthorizationSummaryStatus) -> Bool {
            switch status {
            case .draft:
                return next == GlobalAuthorizationSummaryStatus.suspended || next == GlobalAuthorizationSummaryStatus.closed
            case .pending:
                return next == GlobalAuthorizationSummaryStatus.active || next == GlobalAuthorizationSummaryStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == GlobalAuthorizationSummaryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalAuthorizationSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global authorization summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global authorization summary") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(sequence) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAuthorizationSummary {
            return GlobalAuthorizationSummary(
                code: code,
                title: title,
                facility: facility,
                sequence: sequence,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a global authorization summary in status draft.
    static func newGlobalAuthorizationSummary(_ code: String, title: String) -> GlobalAuthorizationSummary {
        return GlobalAuthorizationSummary(
            code: code,
            title: title,
            facility: "",
            sequence: 0,
            capacity: 0,
            status: GlobalAuthorizationSummaryStatus.draft
        )
    }
}
