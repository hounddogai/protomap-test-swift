import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning plan is in its life cycle.
    enum CleaningPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One cleaning plan, with what the planners need to act on it.
    final class CleaningPlan {
        var code: String
        var title: String
        var maximum: Double
        var limit: Int
        var label: String
        var refills: Int
        var reviewer: String
        var allergy: String
        var amount: Double
        var status: CleaningPlanStatus

        init(code: String, title: String, maximum: Double, limit: Int, label: String, refills: Int, reviewer: String, allergy: String, amount: Double, status: CleaningPlanStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.limit = limit
            self.label = label
            self.refills = refills
            self.reviewer = reviewer
            self.allergy = allergy
            self.amount = amount
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

        func canMoveTo(_ next: CleaningPlanStatus) -> Bool {
            switch status {
            case .new:
                return next == CleaningPlanStatus.running || next == CleaningPlanStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: CleaningPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((Double(refills) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningPlan {
            return CleaningPlan(
                code: code,
                title: title,
                maximum: maximum,
                limit: limit,
                label: label,
                refills: refills,
                reviewer: reviewer,
                allergy: allergy,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a cleaning plan in status new.
    static func newCleaningPlan(_ code: String, title: String) -> CleaningPlan {
        return CleaningPlan(
            code: code,
            title: title,
            maximum: 0.0,
            limit: 0,
            label: "",
            refills: 0,
            reviewer: "",
            allergy: "",
            amount: 0.0,
            status: CleaningPlanStatus.new
        )
    }
}
