import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered skill mix metric is in its life cycle.
    enum TieredSkillMixMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered skill mix metric, with what the planners need to act on it.
    final class TieredSkillMixMetric {
        var code: String
        var name: String
        var unit: String
        var createdAt: Int
        var pinned: Bool
        var approved: Bool
        var attempts: Int
        var label: String
        var country: String
        var status: TieredSkillMixMetricStatus

        init(code: String, name: String, unit: String, createdAt: Int, pinned: Bool, approved: Bool, attempts: Int, label: String, country: String, status: TieredSkillMixMetricStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.createdAt = createdAt
            self.pinned = pinned
            self.approved = approved
            self.attempts = attempts
            self.label = label
            self.country = country
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

        func canMoveTo(_ next: TieredSkillMixMetricStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == TieredSkillMixMetricStatus.completed
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

        func moveTo(_ next: TieredSkillMixMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered skill mix metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("tiered skill mix metric") \(code)"
        }

        func netValue() -> Double {
            return (Double(createdAt) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> TieredSkillMixMetric {
            return TieredSkillMixMetric(
                code: code,
                name: name,
                unit: unit,
                createdAt: createdAt,
                pinned: pinned,
                approved: approved,
                attempts: attempts,
                label: label,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered skill mix metric in status planned.
    static func newTieredSkillMixMetric(_ code: String, name: String) -> TieredSkillMixMetric {
        return TieredSkillMixMetric(
            code: code,
            name: name,
            unit: "",
            createdAt: 0,
            pinned: false,
            approved: false,
            attempts: 0,
            label: "",
            country: "",
            status: TieredSkillMixMetricStatus.planned
        )
    }
}
