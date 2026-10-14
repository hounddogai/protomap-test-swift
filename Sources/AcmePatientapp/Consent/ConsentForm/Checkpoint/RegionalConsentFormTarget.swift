import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional consent form target is in its life cycle.
    enum RegionalConsentFormTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional consent form target and its current status.
    final class RegionalConsentFormTarget {
        var code: String
        var title: String
        var weight: Double
        var category: String
        var unit: String
        var priority: Int
        var status: RegionalConsentFormTargetStatus

        init(code: String, title: String, weight: Double, category: String, unit: String, priority: Int, status: RegionalConsentFormTargetStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.category = category
            self.unit = unit
            self.priority = priority
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

        func canMoveTo(_ next: RegionalConsentFormTargetStatus) -> Bool {
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
                return next == RegionalConsentFormTargetStatus.completed || next == RegionalConsentFormTargetStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalConsentFormTargetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalConsentFormTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional consent form target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return (Double(priority) * weight * 100).rounded() / 100
        }

        func copyValue() -> RegionalConsentFormTarget {
            return RegionalConsentFormTarget(
                code: code,
                title: title,
                weight: weight,
                category: category,
                unit: unit,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional consent form target in status planned.
    static func newRegionalConsentFormTarget(_ code: String, title: String) -> RegionalConsentFormTarget {
        return RegionalConsentFormTarget(
            code: code,
            title: title,
            weight: 0.0,
            category: "",
            unit: "",
            priority: 0,
            status: RegionalConsentFormTargetStatus.planned
        )
    }
}
