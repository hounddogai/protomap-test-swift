import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment allocation is in its life cycle.
    enum AssessmentAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a assessment allocation and its current status.
    final class AssessmentAllocation {
        var code: String
        var name: String
        var weight: Double
        var margin: Double
        var minimum: Double
        var summary: String
        var status: AssessmentAllocationStatus

        init(code: String, name: String, weight: Double, margin: Double, minimum: Double, summary: String, status: AssessmentAllocationStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.margin = margin
            self.minimum = minimum
            self.summary = summary
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

        func canMoveTo(_ next: AssessmentAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AssessmentAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedValue() -> Double {
            return (weight * margin * 100).rounded() / 100
        }

        func copyValue() -> AssessmentAllocation {
            return AssessmentAllocation(
                code: code,
                name: name,
                weight: weight,
                margin: margin,
                minimum: minimum,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a assessment allocation in status requested.
    static func newAssessmentAllocation(_ code: String, name: String) -> AssessmentAllocation {
        return AssessmentAllocation(
            code: code,
            name: name,
            weight: 0.0,
            margin: 0.0,
            minimum: 0.0,
            summary: "",
            status: AssessmentAllocationStatus.requested
        )
    }
}
