import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix template is in its life cycle.
    enum SkillMixTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One skill mix template, with what the planners need to act on it.
    final class SkillMixTemplate {
        var code: String
        var label: String
        var channel: String
        var unit: String
        var margin: Double
        var timezone: String
        var floorValue: Double
        var clinicianID: String
        var status: SkillMixTemplateStatus

        init(code: String, label: String, channel: String, unit: String, margin: Double, timezone: String, floorValue: Double, clinicianID: String, status: SkillMixTemplateStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.unit = unit
            self.margin = margin
            self.timezone = timezone
            self.floorValue = floorValue
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: SkillMixTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == SkillMixTemplateStatus.warming || next == SkillMixTemplateStatus.ready
            case .warming:
                switch next {
                case .draining:
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
                switch next {
                case .stopped:
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

        func moveTo(_ next: SkillMixTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("skill mix template") \(code)"
        }

        func weightedTotal() -> Double {
            return (margin * floorValue * 100).rounded() / 100
        }

        func copyValue() -> SkillMixTemplate {
            return SkillMixTemplate(
                code: code,
                label: label,
                channel: channel,
                unit: unit,
                margin: margin,
                timezone: timezone,
                floorValue: floorValue,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a skill mix template in status idle.
    static func newSkillMixTemplate(_ code: String, label: String) -> SkillMixTemplate {
        return SkillMixTemplate(
            code: code,
            label: label,
            channel: "",
            unit: "",
            margin: 0.0,
            timezone: "",
            floorValue: 0.0,
            clinicianID: "",
            status: SkillMixTemplateStatus.idle
        )
    }
}
