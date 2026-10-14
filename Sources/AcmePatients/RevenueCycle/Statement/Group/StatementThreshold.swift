import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement threshold is in its life cycle.
    enum StatementThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A statement threshold as the statement team keeps it.
    final class StatementThreshold {
        var code: String
        var title: String
        var priority: Int
        var maximum: Double
        var acuity: Int
        var ceiling: Double
        var label: String
        var bed: String
        var status: StatementThresholdStatus

        init(code: String, title: String, priority: Int, maximum: Double, acuity: Int, ceiling: Double, label: String, bed: String, status: StatementThresholdStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.maximum = maximum
            self.acuity = acuity
            self.ceiling = ceiling
            self.label = label
            self.bed = bed
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

        func canMoveTo(_ next: StatementThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StatementThresholdStatus.reopened || next == StatementThresholdStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: StatementThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("statement threshold") \(code)"
        }

        func weightedExposure() -> Double {
            return (ceiling * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> StatementThreshold {
            return StatementThreshold(
                code: code,
                title: title,
                priority: priority,
                maximum: maximum,
                acuity: acuity,
                ceiling: ceiling,
                label: label,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a statement threshold in status open.
    static func newStatementThreshold(_ code: String, title: String) -> StatementThreshold {
        return StatementThreshold(
            code: code,
            title: title,
            priority: 0,
            maximum: 0.0,
            acuity: 0,
            ceiling: 0.0,
            label: "",
            bed: "",
            status: StatementThresholdStatus.`open`
        )
    }
}
