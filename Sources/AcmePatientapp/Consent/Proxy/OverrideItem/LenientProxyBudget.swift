import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy budget is in its life cycle.
    enum LenientProxyBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One lenient proxy budget, with what the planners need to act on it.
    final class LenientProxyBudget {
        var code: String
        var label: String
        var limit: Int
        var timezone: String
        var minimum: Double
        var status: LenientProxyBudgetStatus

        init(code: String, label: String, limit: Int, timezone: String, minimum: Double, status: LenientProxyBudgetStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.timezone = timezone
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientProxyBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LenientProxyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedVolume() -> Double {
            return ((minimum + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LenientProxyBudget {
            return LenientProxyBudget(
                code: code,
                label: label,
                limit: limit,
                timezone: timezone,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient proxy budget in status new.
    static func newLenientProxyBudget(_ code: String, label: String) -> LenientProxyBudget {
        return LenientProxyBudget(
            code: code,
            label: label,
            limit: 0,
            timezone: "",
            minimum: 0.0,
            status: LenientProxyBudgetStatus.new
        )
    }
}
