import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task manifest is in its life cycle.
    enum TaskManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A task manifest. Its code is unique within a tenant.
    final class TaskManifest {
        var code: String
        var label: String
        var ratio: Double
        var archived: Bool
        var score: Double
        var specialty: String
        var allergy: String
        var status: TaskManifestStatus

        init(code: String, label: String, ratio: Double, archived: Bool, score: Double, specialty: String, allergy: String, status: TaskManifestStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.archived = archived
            self.score = score
            self.specialty = specialty
            self.allergy = allergy
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

        func canMoveTo(_ next: TaskManifestStatus) -> Bool {
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
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TaskManifestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("task manifest") \(code)"
        }

        func effectiveValue() -> Double {
            return (ratio * score * 100).rounded() / 100
        }

        func copyValue() -> TaskManifest {
            return TaskManifest(
                code: code,
                label: label,
                ratio: ratio,
                archived: archived,
                score: score,
                specialty: specialty,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a task manifest in status new.
    static func newTaskManifest(_ code: String, label: String) -> TaskManifest {
        return TaskManifest(
            code: code,
            label: label,
            ratio: 0.0,
            archived: false,
            score: 0.0,
            specialty: "",
            allergy: "",
            status: TaskManifestStatus.new
        )
    }
}
