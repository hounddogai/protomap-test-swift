import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual priority target is in its life cycle.
    enum ManualPriorityTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual priority target as the priority team keeps it.
    final class ManualPriorityTarget {
        var code: String
        var label: String
        var bed: String
        var priority: Int
        var allergy: String
        var country: String
        var status: ManualPriorityTargetStatus

        init(code: String, label: String, bed: String, priority: Int, allergy: String, country: String, status: ManualPriorityTargetStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.priority = priority
            self.allergy = allergy
            self.country = country
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

        func canMoveTo(_ next: ManualPriorityTargetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
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

        func moveTo(_ next: ManualPriorityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual priority target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual priority target") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> ManualPriorityTarget {
            return ManualPriorityTarget(
                code: code,
                label: label,
                bed: bed,
                priority: priority,
                allergy: allergy,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual priority target in status new.
    static func newManualPriorityTarget(_ code: String, label: String) -> ManualPriorityTarget {
        return ManualPriorityTarget(
            code: code,
            label: label,
            bed: "",
            priority: 0,
            allergy: "",
            country: "",
            status: ManualPriorityTargetStatus.new
        )
    }
}
