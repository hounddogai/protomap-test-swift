import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation assignment is in its life cycle.
    enum IsolationAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a isolation assignment and its current status.
    final class IsolationAssignment {
        var code: String
        var label: String
        var category: String
        var minimum: Double
        var ratio: Double
        var name: String
        var procedureCode: String
        var status: IsolationAssignmentStatus

        init(code: String, label: String, category: String, minimum: Double, ratio: Double, name: String, procedureCode: String, status: IsolationAssignmentStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.minimum = minimum
            self.ratio = ratio
            self.name = name
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == IsolationAssignmentStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: IsolationAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("isolation assignment") \(code)"
        }

        func netLoad() -> Double {
            return ((minimum + ratio) * 100).rounded() / 100
        }

        func copyValue() -> IsolationAssignment {
            return IsolationAssignment(
                code: code,
                label: label,
                category: category,
                minimum: minimum,
                ratio: ratio,
                name: name,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a isolation assignment in status requested.
    static func newIsolationAssignment(_ code: String, label: String) -> IsolationAssignment {
        return IsolationAssignment(
            code: code,
            label: label,
            category: "",
            minimum: 0.0,
            ratio: 0.0,
            name: "",
            procedureCode: "",
            status: IsolationAssignmentStatus.requested
        )
    }
}
