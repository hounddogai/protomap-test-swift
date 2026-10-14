import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up override is in its life cycle.
    enum FollowUpOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A follow up override as the follow up team keeps it.
    final class FollowUpOverride {
        var code: String
        var label: String
        var copay: Double
        var patientRef: String
        var diagnosisCode: String
        var status: FollowUpOverrideStatus

        init(code: String, label: String, copay: Double, patientRef: String, diagnosisCode: String, status: FollowUpOverrideStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: FollowUpOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == FollowUpOverrideStatus.running || next == FollowUpOverrideStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FollowUpOverrideStatus.done || next == FollowUpOverrideStatus.failed
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

        func moveTo(_ next: FollowUpOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> FollowUpOverride {
            return FollowUpOverride(
                code: code,
                label: label,
                copay: copay,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a follow up override in status new.
    static func newFollowUpOverride(_ code: String, label: String) -> FollowUpOverride {
        return FollowUpOverride(
            code: code,
            label: label,
            copay: 0.0,
            patientRef: "",
            diagnosisCode: "",
            status: FollowUpOverrideStatus.new
        )
    }
}
