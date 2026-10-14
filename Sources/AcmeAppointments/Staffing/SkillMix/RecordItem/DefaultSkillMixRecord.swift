import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default skill mix record is in its life cycle.
    enum DefaultSkillMixRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default skill mix record. Its code is unique within a tenant.
    final class DefaultSkillMixRecord {
        var code: String
        var label: String
        var startsAt: Int
        var country: String
        var timezone: String
        var ceiling: Double
        var status: DefaultSkillMixRecordStatus

        init(code: String, label: String, startsAt: Int, country: String, timezone: String, ceiling: Double, status: DefaultSkillMixRecordStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.country = country
            self.timezone = timezone
            self.ceiling = ceiling
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

        func canMoveTo(_ next: DefaultSkillMixRecordStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultSkillMixRecordStatus.warming
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultSkillMixRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultSkillMixRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default skill mix record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return (Double(startsAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> DefaultSkillMixRecord {
            return DefaultSkillMixRecord(
                code: code,
                label: label,
                startsAt: startsAt,
                country: country,
                timezone: timezone,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default skill mix record in status idle.
    static func newDefaultSkillMixRecord(_ code: String, label: String) -> DefaultSkillMixRecord {
        return DefaultSkillMixRecord(
            code: code,
            label: label,
            startsAt: 0,
            country: "",
            timezone: "",
            ceiling: 0.0,
            status: DefaultSkillMixRecordStatus.idle
        )
    }
}
