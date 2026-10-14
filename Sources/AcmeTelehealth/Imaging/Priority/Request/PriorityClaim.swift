import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority claim is in its life cycle.
    enum PriorityClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A priority claim. Its code is unique within a tenant.
    final class PriorityClaim {
        var code: String
        var title: String
        var active: Bool
        var revision: Int
        var encounterID: String
        var patientRef: String
        var sequence: Int
        var category: String
        var status: PriorityClaimStatus

        init(code: String, title: String, active: Bool, revision: Int, encounterID: String, patientRef: String, sequence: Int, category: String, status: PriorityClaimStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.revision = revision
            self.encounterID = encounterID
            self.patientRef = patientRef
            self.sequence = sequence
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityClaimStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PriorityClaimStatus.withdrawn
            case .rejected:
                return next == PriorityClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("priority claim") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(sequence) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityClaim {
            return PriorityClaim(
                code: code,
                title: title,
                active: active,
                revision: revision,
                encounterID: encounterID,
                patientRef: patientRef,
                sequence: sequence,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a priority claim in status proposed.
    static func newPriorityClaim(_ code: String, title: String) -> PriorityClaim {
        return PriorityClaim(
            code: code,
            title: title,
            active: false,
            revision: 0,
            encounterID: "",
            patientRef: "",
            sequence: 0,
            category: "",
            status: PriorityClaimStatus.proposed
        )
    }
}
