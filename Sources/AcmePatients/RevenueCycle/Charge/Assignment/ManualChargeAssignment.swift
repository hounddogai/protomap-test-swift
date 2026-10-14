import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual charge assignment is in its life cycle.
    enum ManualChargeAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual charge assignment. Its code is unique within a tenant.
    final class ManualChargeAssignment {
        var code: String
        var name: String
        var unit: String
        var description: String
        var specialty: String
        var score: Double
        var status: ManualChargeAssignmentStatus

        init(code: String, name: String, unit: String, description: String, specialty: String, score: Double, status: ManualChargeAssignmentStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.description = description
            self.specialty = specialty
            self.score = score
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

        func canMoveTo(_ next: ManualChargeAssignmentStatus) -> Bool {
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
                return next == ManualChargeAssignmentStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ManualChargeAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualChargeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual charge assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ManualChargeAssignment {
            return ManualChargeAssignment(
                code: code,
                name: name,
                unit: unit,
                description: description,
                specialty: specialty,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a manual charge assignment in status idle.
    static func newManualChargeAssignment(_ code: String, name: String) -> ManualChargeAssignment {
        return ManualChargeAssignment(
            code: code,
            name: name,
            unit: "",
            description: "",
            specialty: "",
            score: 0.0,
            status: ManualChargeAssignmentStatus.idle
        )
    }
}
