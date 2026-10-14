import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding assignment is in its life cycle.
    enum RoundingAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rounding assignment, with what the planners need to act on it.
    final class RoundingAssignment {
        var code: String
        var name: String
        var threshold: Double
        var acuity: Int
        var cost: Double
        var notes: String
        var createdAt: Int
        var updatedAt: Int
        var status: RoundingAssignmentStatus

        init(code: String, name: String, threshold: Double, acuity: Int, cost: Double, notes: String, createdAt: Int, updatedAt: Int, status: RoundingAssignmentStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.acuity = acuity
            self.cost = cost
            self.notes = notes
            self.createdAt = createdAt
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RoundingAssignmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RoundingAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rounding assignment") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(acuity) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingAssignment {
            return RoundingAssignment(
                code: code,
                name: name,
                threshold: threshold,
                acuity: acuity,
                cost: cost,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding assignment in status created.
    static func newRoundingAssignment(_ code: String, name: String) -> RoundingAssignment {
        return RoundingAssignment(
            code: code,
            name: name,
            threshold: 0.0,
            acuity: 0,
            cost: 0.0,
            notes: "",
            createdAt: 0,
            updatedAt: 0,
            status: RoundingAssignmentStatus.created
        )
    }
}
