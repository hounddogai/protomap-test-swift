import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default risk score window is in its life cycle.
    enum DefaultRiskScoreWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One default risk score window, with what the planners need to act on it.
    final class DefaultRiskScoreWindow {
        var code: String
        var title: String
        var durationMinutes: Int
        var cost: Double
        var threshold: Double
        var weight: Double
        var status: DefaultRiskScoreWindowStatus

        init(code: String, title: String, durationMinutes: Int, cost: Double, threshold: Double, weight: Double, status: DefaultRiskScoreWindowStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.threshold = threshold
            self.weight = weight
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

        func canMoveTo(_ next: DefaultRiskScoreWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == DefaultRiskScoreWindowStatus.active
            case .pending:
                return next == DefaultRiskScoreWindowStatus.suspended || next == DefaultRiskScoreWindowStatus.closed
            case .active:
                return next == DefaultRiskScoreWindowStatus.closed
            case .suspended:
                return next == DefaultRiskScoreWindowStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRiskScoreWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default risk score window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((threshold + cost) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRiskScoreWindow {
            return DefaultRiskScoreWindow(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                cost: cost,
                threshold: threshold,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default risk score window in status draft.
    static func newDefaultRiskScoreWindow(_ code: String, title: String) -> DefaultRiskScoreWindow {
        return DefaultRiskScoreWindow(
            code: code,
            title: title,
            durationMinutes: 0,
            cost: 0.0,
            threshold: 0.0,
            weight: 0.0,
            status: DefaultRiskScoreWindowStatus.draft
        )
    }
}
