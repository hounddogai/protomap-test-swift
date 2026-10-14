import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback isolation metric is in its life cycle.
    enum FallbackIsolationMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One fallback isolation metric, with what the planners need to act on it.
    final class FallbackIsolationMetric {
        var code: String
        var title: String
        var payer: String
        var contactEmail: String
        var allergy: String
        var amount: Double
        var status: FallbackIsolationMetricStatus

        init(code: String, title: String, payer: String, contactEmail: String, allergy: String, amount: Double, status: FallbackIsolationMetricStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackIsolationMetricStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FallbackIsolationMetricStatus.completed || next == FallbackIsolationMetricStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: FallbackIsolationMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback isolation metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback isolation metric") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> FallbackIsolationMetric {
            return FallbackIsolationMetric(
                code: code,
                title: title,
                payer: payer,
                contactEmail: contactEmail,
                allergy: allergy,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback isolation metric in status planned.
    static func newFallbackIsolationMetric(_ code: String, title: String) -> FallbackIsolationMetric {
        return FallbackIsolationMetric(
            code: code,
            title: title,
            payer: "",
            contactEmail: "",
            allergy: "",
            amount: 0.0,
            status: FallbackIsolationMetricStatus.planned
        )
    }
}
