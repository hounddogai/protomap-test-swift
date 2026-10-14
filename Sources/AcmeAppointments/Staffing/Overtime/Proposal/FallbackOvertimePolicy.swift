import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback overtime policy is in its life cycle.
    enum FallbackOvertimePolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a fallback overtime policy and its current status.
    final class FallbackOvertimePolicy {
        var code: String
        var name: String
        var windowDays: Int
        var budget: Double
        var ceiling: Double
        var category: String
        var channel: String
        var dosageMg: Double
        var retries: Int
        var status: FallbackOvertimePolicyStatus

        init(code: String, name: String, windowDays: Int, budget: Double, ceiling: Double, category: String, channel: String, dosageMg: Double, retries: Int, status: FallbackOvertimePolicyStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.budget = budget
            self.ceiling = ceiling
            self.category = category
            self.channel = channel
            self.dosageMg = dosageMg
            self.retries = retries
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

        func canMoveTo(_ next: FallbackOvertimePolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FallbackOvertimePolicyStatus.reopened || next == FallbackOvertimePolicyStatus.archived
            case .resolved:
                return next == FallbackOvertimePolicyStatus.archived
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

        func moveTo(_ next: FallbackOvertimePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback overtime policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedLoad() -> Double {
            return (ceiling * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> FallbackOvertimePolicy {
            return FallbackOvertimePolicy(
                code: code,
                name: name,
                windowDays: windowDays,
                budget: budget,
                ceiling: ceiling,
                category: category,
                channel: channel,
                dosageMg: dosageMg,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback overtime policy in status open.
    static func newFallbackOvertimePolicy(_ code: String, name: String) -> FallbackOvertimePolicy {
        return FallbackOvertimePolicy(
            code: code,
            name: name,
            windowDays: 0,
            budget: 0.0,
            ceiling: 0.0,
            category: "",
            channel: "",
            dosageMg: 0.0,
            retries: 0,
            status: FallbackOvertimePolicyStatus.`open`
        )
    }
}
