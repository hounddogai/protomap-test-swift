import AcmePlatform
import Foundation

extension Labs {
    /// Where a global courier milestone is in its life cycle.
    enum GlobalCourierMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global courier milestone. Its code is unique within a tenant.
    final class GlobalCourierMilestone {
        var code: String
        var label: String
        var diagnosisCode: String
        var timezone: String
        var allergy: String
        var source: String
        var region: String
        var dosageMg: Double
        var status: GlobalCourierMilestoneStatus

        init(code: String, label: String, diagnosisCode: String, timezone: String, allergy: String, source: String, region: String, dosageMg: Double, status: GlobalCourierMilestoneStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.allergy = allergy
            self.source = source
            self.region = region
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: GlobalCourierMilestoneStatus) -> Bool {
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
                return next == GlobalCourierMilestoneStatus.done
            case .running:
                return next == GlobalCourierMilestoneStatus.done
            case .done:
                return next == GlobalCourierMilestoneStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCourierMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global courier milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> GlobalCourierMilestone {
            return GlobalCourierMilestone(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                allergy: allergy,
                source: source,
                region: region,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global courier milestone in status new.
    static func newGlobalCourierMilestone(_ code: String, label: String) -> GlobalCourierMilestone {
        return GlobalCourierMilestone(
            code: code,
            label: label,
            diagnosisCode: "",
            timezone: "",
            allergy: "",
            source: "",
            region: "",
            dosageMg: 0.0,
            status: GlobalCourierMilestoneStatus.new
        )
    }
}
