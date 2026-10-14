import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix segment is in its life cycle.
    enum SkillMixSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a skill mix segment and its current status.
    final class SkillMixSegment {
        var code: String
        var label: String
        var segment: String
        var rate: Double
        var active: Bool
        var acuity: Int
        var copay: Double
        var status: SkillMixSegmentStatus

        init(code: String, label: String, segment: String, rate: Double, active: Bool, acuity: Int, copay: Double, status: SkillMixSegmentStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.rate = rate
            self.active = active
            self.acuity = acuity
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == SkillMixSegmentStatus.published || next == SkillMixSegmentStatus.retired
            case .validated:
                return next == SkillMixSegmentStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SkillMixSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("skill mix segment") \(code)"
        }

        func weightedLoad() -> Double {
            return (copay * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixSegment {
            return SkillMixSegment(
                code: code,
                label: label,
                segment: segment,
                rate: rate,
                active: active,
                acuity: acuity,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a skill mix segment in status created.
    static func newSkillMixSegment(_ code: String, label: String) -> SkillMixSegment {
        return SkillMixSegment(
            code: code,
            label: label,
            segment: "",
            rate: 0.0,
            active: false,
            acuity: 0,
            copay: 0.0,
            status: SkillMixSegmentStatus.created
        )
    }
}
