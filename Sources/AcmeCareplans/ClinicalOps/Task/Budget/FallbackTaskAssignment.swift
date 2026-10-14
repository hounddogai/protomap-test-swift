import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback task assignment is in its life cycle.
    enum FallbackTaskAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback task assignment. Its code is unique within a tenant.
    final class FallbackTaskAssignment {
        var code: String
        var label: String
        var copay: Double
        var channel: String
        var archived: Bool
        var cost: Double
        var limit: Int
        var notes: String
        var allergy: String
        var description: String
        var status: FallbackTaskAssignmentStatus

        init(code: String, label: String, copay: Double, channel: String, archived: Bool, cost: Double, limit: Int, notes: String, allergy: String, description: String, status: FallbackTaskAssignmentStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.channel = channel
            self.archived = archived
            self.cost = cost
            self.limit = limit
            self.notes = notes
            self.allergy = allergy
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackTaskAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FallbackTaskAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackTaskAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback task assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return ((cost - copay) * 100).rounded() / 100
        }

        func copyValue() -> FallbackTaskAssignment {
            return FallbackTaskAssignment(
                code: code,
                label: label,
                copay: copay,
                channel: channel,
                archived: archived,
                cost: cost,
                limit: limit,
                notes: notes,
                allergy: allergy,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback task assignment in status idle.
    static func newFallbackTaskAssignment(_ code: String, label: String) -> FallbackTaskAssignment {
        return FallbackTaskAssignment(
            code: code,
            label: label,
            copay: 0.0,
            channel: "",
            archived: false,
            cost: 0.0,
            limit: 0,
            notes: "",
            allergy: "",
            description: "",
            status: FallbackTaskAssignmentStatus.idle
        )
    }
}
