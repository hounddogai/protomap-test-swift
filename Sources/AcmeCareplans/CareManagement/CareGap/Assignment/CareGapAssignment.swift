import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap assignment is in its life cycle.
    enum CareGapAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One care gap assignment, with what the planners need to act on it.
    final class CareGapAssignment {
        var code: String
        var name: String
        var refills: Int
        var budget: Double
        var procedureCode: String
        var status: CareGapAssignmentStatus

        init(code: String, name: String, refills: Int, budget: Double, procedureCode: String, status: CareGapAssignmentStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.budget = budget
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: CareGapAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
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
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CareGapAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(refills) + budget) * 100).rounded() / 100
        }

        func copyValue() -> CareGapAssignment {
            return CareGapAssignment(
                code: code,
                name: name,
                refills: refills,
                budget: budget,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care gap assignment in status idle.
    static func newCareGapAssignment(_ code: String, name: String) -> CareGapAssignment {
        return CareGapAssignment(
            code: code,
            name: name,
            refills: 0,
            budget: 0.0,
            procedureCode: "",
            status: CareGapAssignmentStatus.idle
        )
    }
}
