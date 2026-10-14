import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall group is in its life cycle.
    enum RecallGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One recall group, with what the planners need to act on it.
    final class RecallGroup {
        var code: String
        var name: String
        var timezone: String
        var pinned: Bool
        var visitMinutes: Int
        var maximum: Double
        var endsAt: Int
        var quantity: Int
        var status: RecallGroupStatus

        init(code: String, name: String, timezone: String, pinned: Bool, visitMinutes: Int, maximum: Double, endsAt: Int, quantity: Int, status: RecallGroupStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.pinned = pinned
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.endsAt = endsAt
            self.quantity = quantity
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

        func canMoveTo(_ next: RecallGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == RecallGroupStatus.suspended || next == RecallGroupStatus.closed
            case .pending:
                return next == RecallGroupStatus.active || next == RecallGroupStatus.suspended
            case .active:
                return next == RecallGroupStatus.suspended || next == RecallGroupStatus.closed
            case .suspended:
                return next == RecallGroupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return (Double(endsAt) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RecallGroup {
            return RecallGroup(
                code: code,
                name: name,
                timezone: timezone,
                pinned: pinned,
                visitMinutes: visitMinutes,
                maximum: maximum,
                endsAt: endsAt,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall group in status draft.
    static func newRecallGroup(_ code: String, name: String) -> RecallGroup {
        return RecallGroup(
            code: code,
            name: name,
            timezone: "",
            pinned: false,
            visitMinutes: 0,
            maximum: 0.0,
            endsAt: 0,
            quantity: 0,
            status: RecallGroupStatus.draft
        )
    }
}
