import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task profile is in its life cycle.
    enum TaskProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A task profile. Its code is unique within a tenant.
    final class TaskProfile {
        var code: String
        var label: String
        var bed: String
        var budget: Double
        var allergy: String
        var acuity: Int
        var windowDays: Int
        var clinicianID: String
        var status: TaskProfileStatus

        init(code: String, label: String, bed: String, budget: Double, allergy: String, acuity: Int, windowDays: Int, clinicianID: String, status: TaskProfileStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.budget = budget
            self.allergy = allergy
            self.acuity = acuity
            self.windowDays = windowDays
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: TaskProfileStatus) -> Bool {
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
                switch next {
                case .running, .done:
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
                return next == TaskProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netVolume() -> Double {
            return ((budget - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TaskProfile {
            return TaskProfile(
                code: code,
                label: label,
                bed: bed,
                budget: budget,
                allergy: allergy,
                acuity: acuity,
                windowDays: windowDays,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a task profile in status new.
    static func newTaskProfile(_ code: String, label: String) -> TaskProfile {
        return TaskProfile(
            code: code,
            label: label,
            bed: "",
            budget: 0.0,
            allergy: "",
            acuity: 0,
            windowDays: 0,
            clinicianID: "",
            status: TaskProfileStatus.new
        )
    }
}
