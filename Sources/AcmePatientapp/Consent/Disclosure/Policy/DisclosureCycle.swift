import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure cycle is in its life cycle.
    enum DisclosureCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A disclosure cycle. Its code is unique within a tenant.
    final class DisclosureCycle {
        var code: String
        var title: String
        var score: Double
        var pinned: Bool
        var retries: Int
        var active: Bool
        var status: DisclosureCycleStatus

        init(code: String, title: String, score: Double, pinned: Bool, retries: Int, active: Bool, status: DisclosureCycleStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.pinned = pinned
            self.retries = retries
            self.active = active
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

        func canMoveTo(_ next: DisclosureCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == DisclosureCycleStatus.retired
            case .validated:
                return next == DisclosureCycleStatus.published || next == DisclosureCycleStatus.retired
            case .published:
                return next == DisclosureCycleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("disclosure cycle") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(retries) - score) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureCycle {
            return DisclosureCycle(
                code: code,
                title: title,
                score: score,
                pinned: pinned,
                retries: retries,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a disclosure cycle in status created.
    static func newDisclosureCycle(_ code: String, title: String) -> DisclosureCycle {
        return DisclosureCycle(
            code: code,
            title: title,
            score: 0.0,
            pinned: false,
            retries: 0,
            active: false,
            status: DisclosureCycleStatus.created
        )
    }
}
