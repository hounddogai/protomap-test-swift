import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan policy is in its life cycle.
    enum AcuityPlanPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a acuity plan policy and its current status.
    final class AcuityPlanPolicy {
        var code: String
        var label: String
        var summary: String
        var bed: String
        var timezone: String
        var notes: String
        var specialty: String
        var ratio: Double
        var status: AcuityPlanPolicyStatus

        init(code: String, label: String, summary: String, bed: String, timezone: String, notes: String, specialty: String, ratio: Double, status: AcuityPlanPolicyStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.bed = bed
            self.timezone = timezone
            self.notes = notes
            self.specialty = specialty
            self.ratio = ratio
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

        func canMoveTo(_ next: AcuityPlanPolicyStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AcuityPlanPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> AcuityPlanPolicy {
            return AcuityPlanPolicy(
                code: code,
                label: label,
                summary: summary,
                bed: bed,
                timezone: timezone,
                notes: notes,
                specialty: specialty,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan policy in status created.
    static func newAcuityPlanPolicy(_ code: String, label: String) -> AcuityPlanPolicy {
        return AcuityPlanPolicy(
            code: code,
            label: label,
            summary: "",
            bed: "",
            timezone: "",
            notes: "",
            specialty: "",
            ratio: 0.0,
            status: AcuityPlanPolicyStatus.created
        )
    }
}
