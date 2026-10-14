import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study bundle is in its life cycle.
    enum StudyBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A study bundle as the study team keeps it.
    final class StudyBundle {
        var code: String
        var label: String
        var ownerID: String
        var summary: String
        var budget: Double
        var notes: String
        var bed: String
        var specialty: String
        var weight: Double
        var refills: Int
        var procedureCode: String
        var status: StudyBundleStatus

        init(code: String, label: String, ownerID: String, summary: String, budget: Double, notes: String, bed: String, specialty: String, weight: Double, refills: Int, procedureCode: String, status: StudyBundleStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.summary = summary
            self.budget = budget
            self.notes = notes
            self.bed = bed
            self.specialty = specialty
            self.weight = weight
            self.refills = refills
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: StudyBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StudyBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("study bundle") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(refills) + weight) * 100).rounded() / 100
        }

        func copyValue() -> StudyBundle {
            return StudyBundle(
                code: code,
                label: label,
                ownerID: ownerID,
                summary: summary,
                budget: budget,
                notes: notes,
                bed: bed,
                specialty: specialty,
                weight: weight,
                refills: refills,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a study bundle in status planned.
    static func newStudyBundle(_ code: String, label: String) -> StudyBundle {
        return StudyBundle(
            code: code,
            label: label,
            ownerID: "",
            summary: "",
            budget: 0.0,
            notes: "",
            bed: "",
            specialty: "",
            weight: 0.0,
            refills: 0,
            procedureCode: "",
            status: StudyBundleStatus.planned
        )
    }
}
