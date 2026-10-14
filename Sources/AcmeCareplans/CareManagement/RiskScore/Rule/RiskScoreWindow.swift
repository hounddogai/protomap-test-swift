import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score window is in its life cycle.
    enum RiskScoreWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A risk score window as the risk score team keeps it.
    final class RiskScoreWindow {
        var code: String
        var title: String
        var capacity: Int
        var rate: Double
        var acuity: Int
        var summary: String
        var status: RiskScoreWindowStatus

        init(code: String, title: String, capacity: Int, rate: Double, acuity: Int, summary: String, status: RiskScoreWindowStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.rate = rate
            self.acuity = acuity
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreWindowStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RiskScoreWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(capacity) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreWindow {
            return RiskScoreWindow(
                code: code,
                title: title,
                capacity: capacity,
                rate: rate,
                acuity: acuity,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a risk score window in status open.
    static func newRiskScoreWindow(_ code: String, title: String) -> RiskScoreWindow {
        return RiskScoreWindow(
            code: code,
            title: title,
            capacity: 0,
            rate: 0.0,
            acuity: 0,
            summary: "",
            status: RiskScoreWindowStatus.`open`
        )
    }
}
