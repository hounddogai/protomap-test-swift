import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness assignment is in its life cycle.
    enum WitnessAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A witness assignment. Its code is unique within a tenant.
    final class WitnessAssignment {
        var code: String
        var title: String
        var category: String
        var procedureCode: String
        var minimum: Double
        var floorValue: Double
        var threshold: Double
        var dosageMg: Double
        var graceDays: Int
        var description: String
        var status: WitnessAssignmentStatus

        init(code: String, title: String, category: String, procedureCode: String, minimum: Double, floorValue: Double, threshold: Double, dosageMg: Double, graceDays: Int, description: String, status: WitnessAssignmentStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.floorValue = floorValue
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.graceDays = graceDays
            self.description = description
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

        func canMoveTo(_ next: WitnessAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == WitnessAssignmentStatus.validated || next == WitnessAssignmentStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WitnessAssignmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return (dosageMg * threshold * 100).rounded() / 100
        }

        func copyValue() -> WitnessAssignment {
            return WitnessAssignment(
                code: code,
                title: title,
                category: category,
                procedureCode: procedureCode,
                minimum: minimum,
                floorValue: floorValue,
                threshold: threshold,
                dosageMg: dosageMg,
                graceDays: graceDays,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a witness assignment in status created.
    static func newWitnessAssignment(_ code: String, title: String) -> WitnessAssignment {
        return WitnessAssignment(
            code: code,
            title: title,
            category: "",
            procedureCode: "",
            minimum: 0.0,
            floorValue: 0.0,
            threshold: 0.0,
            dosageMg: 0.0,
            graceDays: 0,
            description: "",
            status: WitnessAssignmentStatus.created
        )
    }
}
