import AcmePlatform
import Foundation

extension Labs {
    /// Where a result group is in its life cycle.
    enum ResultGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A result group as the result team keeps it.
    final class ResultGroup {
        var code: String
        var title: String
        var pinned: Bool
        var visible: Bool
        var approved: Bool
        var maximum: Double
        var visitMinutes: Int
        var status: ResultGroupStatus

        init(code: String, title: String, pinned: Bool, visible: Bool, approved: Bool, maximum: Double, visitMinutes: Int, status: ResultGroupStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.visible = visible
            self.approved = approved
            self.maximum = maximum
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ResultGroupStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ResultGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedExposure() -> Double {
            return (maximum * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ResultGroup {
            return ResultGroup(
                code: code,
                title: title,
                pinned: pinned,
                visible: visible,
                approved: approved,
                maximum: maximum,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a result group in status proposed.
    static func newResultGroup(_ code: String, title: String) -> ResultGroup {
        return ResultGroup(
            code: code,
            title: title,
            pinned: false,
            visible: false,
            approved: false,
            maximum: 0.0,
            visitMinutes: 0,
            status: ResultGroupStatus.proposed
        )
    }
}
