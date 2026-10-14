import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending statement target is in its life cycle.
    enum PendingStatementTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending statement target as the statement team keeps it.
    final class PendingStatementTarget {
        var code: String
        var name: String
        var category: String
        var allergy: String
        var threshold: Double
        var pinned: Bool
        var acuity: Int
        var budget: Double
        var quantity: Int
        var bed: String
        var status: PendingStatementTargetStatus

        init(code: String, name: String, category: String, allergy: String, threshold: Double, pinned: Bool, acuity: Int, budget: Double, quantity: Int, bed: String, status: PendingStatementTargetStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.allergy = allergy
            self.threshold = threshold
            self.pinned = pinned
            self.acuity = acuity
            self.budget = budget
            self.quantity = quantity
            self.bed = bed
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

        func canMoveTo(_ next: PendingStatementTargetStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingStatementTargetStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PendingStatementTargetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingStatementTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending statement target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending statement target") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((budget + threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingStatementTarget {
            return PendingStatementTarget(
                code: code,
                name: name,
                category: category,
                allergy: allergy,
                threshold: threshold,
                pinned: pinned,
                acuity: acuity,
                budget: budget,
                quantity: quantity,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending statement target in status planned.
    static func newPendingStatementTarget(_ code: String, name: String) -> PendingStatementTarget {
        return PendingStatementTarget(
            code: code,
            name: name,
            category: "",
            allergy: "",
            threshold: 0.0,
            pinned: false,
            acuity: 0,
            budget: 0.0,
            quantity: 0,
            bed: "",
            status: PendingStatementTargetStatus.planned
        )
    }
}
