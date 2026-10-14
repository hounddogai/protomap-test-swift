import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment snapshot is in its life cycle.
    enum AssessmentSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A assessment snapshot as the assessment team keeps it.
    final class AssessmentSnapshot {
        var code: String
        var label: String
        var allergy: String
        var endsAt: Int
        var durationMinutes: Int
        var budget: Double
        var attempts: Int
        var contactEmail: String
        var name: String
        var status: AssessmentSnapshotStatus

        init(code: String, label: String, allergy: String, endsAt: Int, durationMinutes: Int, budget: Double, attempts: Int, contactEmail: String, name: String, status: AssessmentSnapshotStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.endsAt = endsAt
            self.durationMinutes = durationMinutes
            self.budget = budget
            self.attempts = attempts
            self.contactEmail = contactEmail
            self.name = name
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

        func canMoveTo(_ next: AssessmentSnapshotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
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

        func moveTo(_ next: AssessmentSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return (Double(attempts) * budget * 100).rounded() / 100
        }

        func copyValue() -> AssessmentSnapshot {
            return AssessmentSnapshot(
                code: code,
                label: label,
                allergy: allergy,
                endsAt: endsAt,
                durationMinutes: durationMinutes,
                budget: budget,
                attempts: attempts,
                contactEmail: contactEmail,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a assessment snapshot in status new.
    static func newAssessmentSnapshot(_ code: String, label: String) -> AssessmentSnapshot {
        return AssessmentSnapshot(
            code: code,
            label: label,
            allergy: "",
            endsAt: 0,
            durationMinutes: 0,
            budget: 0.0,
            attempts: 0,
            contactEmail: "",
            name: "",
            status: AssessmentSnapshotStatus.new
        )
    }
}
