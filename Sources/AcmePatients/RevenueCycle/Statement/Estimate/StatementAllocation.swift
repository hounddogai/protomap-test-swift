import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement allocation is in its life cycle.
    enum StatementAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A statement allocation. Its code is unique within a tenant.
    final class StatementAllocation {
        var code: String
        var label: String
        var threshold: Double
        var graceDays: Int
        var score: Double
        var margin: Double
        var windowDays: Int
        var copay: Double
        var contactEmail: String
        var status: StatementAllocationStatus

        init(code: String, label: String, threshold: Double, graceDays: Int, score: Double, margin: Double, windowDays: Int, copay: Double, contactEmail: String, status: StatementAllocationStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.graceDays = graceDays
            self.score = score
            self.margin = margin
            self.windowDays = windowDays
            self.copay = copay
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StatementAllocationStatus.stopped
            case .draining:
                return next == StatementAllocationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("statement allocation") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((copay - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> StatementAllocation {
            return StatementAllocation(
                code: code,
                label: label,
                threshold: threshold,
                graceDays: graceDays,
                score: score,
                margin: margin,
                windowDays: windowDays,
                copay: copay,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a statement allocation in status idle.
    static func newStatementAllocation(_ code: String, label: String) -> StatementAllocation {
        return StatementAllocation(
            code: code,
            label: label,
            threshold: 0.0,
            graceDays: 0,
            score: 0.0,
            margin: 0.0,
            windowDays: 0,
            copay: 0.0,
            contactEmail: "",
            status: StatementAllocationStatus.idle
        )
    }
}
