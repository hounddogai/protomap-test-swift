import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted claim profile is in its life cycle.
    enum WeightedClaimProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a weighted claim profile and its current status.
    final class WeightedClaimProfile {
        var code: String
        var label: String
        var archived: Bool
        var threshold: Double
        var checksum: String
        var notes: String
        var patientRef: String
        var priority: Int
        var dosageMg: Double
        var copay: Double
        var contactEmail: String
        var status: WeightedClaimProfileStatus

        init(code: String, label: String, archived: Bool, threshold: Double, checksum: String, notes: String, patientRef: String, priority: Int, dosageMg: Double, copay: Double, contactEmail: String, status: WeightedClaimProfileStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.threshold = threshold
            self.checksum = checksum
            self.notes = notes
            self.patientRef = patientRef
            self.priority = priority
            self.dosageMg = dosageMg
            self.copay = copay
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: WeightedClaimProfileStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == WeightedClaimProfileStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == WeightedClaimProfileStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedClaimProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted claim profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((dosageMg + threshold) * 100).rounded() / 100
        }

        func copyValue() -> WeightedClaimProfile {
            return WeightedClaimProfile(
                code: code,
                label: label,
                archived: archived,
                threshold: threshold,
                checksum: checksum,
                notes: notes,
                patientRef: patientRef,
                priority: priority,
                dosageMg: dosageMg,
                copay: copay,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted claim profile in status planned.
    static func newWeightedClaimProfile(_ code: String, label: String) -> WeightedClaimProfile {
        return WeightedClaimProfile(
            code: code,
            label: label,
            archived: false,
            threshold: 0.0,
            checksum: "",
            notes: "",
            patientRef: "",
            priority: 0,
            dosageMg: 0.0,
            copay: 0.0,
            contactEmail: "",
            status: WeightedClaimProfileStatus.planned
        )
    }
}
