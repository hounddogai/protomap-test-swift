import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback priority group is in its life cycle.
    enum FallbackPriorityGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback priority group. Its code is unique within a tenant.
    final class FallbackPriorityGroup {
        var code: String
        var label: String
        var bed: String
        var category: String
        var limit: Int
        var attempts: Int
        var acuity: Int
        var threshold: Double
        var maximum: Double
        var cost: Double
        var status: FallbackPriorityGroupStatus

        init(code: String, label: String, bed: String, category: String, limit: Int, attempts: Int, acuity: Int, threshold: Double, maximum: Double, cost: Double, status: FallbackPriorityGroupStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.category = category
            self.limit = limit
            self.attempts = attempts
            self.acuity = acuity
            self.threshold = threshold
            self.maximum = maximum
            self.cost = cost
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

        func canMoveTo(_ next: FallbackPriorityGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FallbackPriorityGroupStatus.done || next == FallbackPriorityGroupStatus.failed
            case .done:
                return next == FallbackPriorityGroupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackPriorityGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback priority group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback priority group") \(code)"
        }

        func projectedTotal() -> Double {
            return ((cost - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackPriorityGroup {
            return FallbackPriorityGroup(
                code: code,
                label: label,
                bed: bed,
                category: category,
                limit: limit,
                attempts: attempts,
                acuity: acuity,
                threshold: threshold,
                maximum: maximum,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback priority group in status new.
    static func newFallbackPriorityGroup(_ code: String, label: String) -> FallbackPriorityGroup {
        return FallbackPriorityGroup(
            code: code,
            label: label,
            bed: "",
            category: "",
            limit: 0,
            attempts: 0,
            acuity: 0,
            threshold: 0.0,
            maximum: 0.0,
            cost: 0.0,
            status: FallbackPriorityGroupStatus.new
        )
    }
}
