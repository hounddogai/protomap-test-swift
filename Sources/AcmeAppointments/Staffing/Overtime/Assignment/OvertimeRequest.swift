import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime request is in its life cycle.
    enum OvertimeRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One overtime request, with what the planners need to act on it.
    final class OvertimeRequest {
        var code: String
        var name: String
        var rate: Double
        var pinned: Bool
        var amount: Double
        var archived: Bool
        var status: OvertimeRequestStatus

        init(code: String, name: String, rate: Double, pinned: Bool, amount: Double, archived: Bool, status: OvertimeRequestStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.pinned = pinned
            self.amount = amount
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

        func canMoveTo(_ next: OvertimeRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == OvertimeRequestStatus.suspended || next == OvertimeRequestStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: OvertimeRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("overtime request") \(code)"
        }

        func projectedVolume() -> Double {
            return ((rate + amount) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeRequest {
            return OvertimeRequest(
                code: code,
                name: name,
                rate: rate,
                pinned: pinned,
                amount: amount,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a overtime request in status draft.
    static func newOvertimeRequest(_ code: String, name: String) -> OvertimeRequest {
        return OvertimeRequest(
            code: code,
            name: name,
            rate: 0.0,
            pinned: false,
            amount: 0.0,
            archived: false,
            status: OvertimeRequestStatus.draft
        )
    }
}
