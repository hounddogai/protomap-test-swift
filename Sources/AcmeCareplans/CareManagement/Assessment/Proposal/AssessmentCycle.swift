import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment cycle is in its life cycle.
    enum AssessmentCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A assessment cycle. Its code is unique within a tenant.
    final class AssessmentCycle {
        var code: String
        var title: String
        var durationMinutes: Int
        var country: String
        var description: String
        var minimum: Double
        var status: AssessmentCycleStatus

        init(code: String, title: String, durationMinutes: Int, country: String, description: String, minimum: Double, status: AssessmentCycleStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.country = country
            self.description = description
            self.minimum = minimum
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

        func canMoveTo(_ next: AssessmentCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == AssessmentCycleStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AssessmentCycleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (Double(durationMinutes) * minimum * 100).rounded() / 100
        }

        func copyValue() -> AssessmentCycle {
            return AssessmentCycle(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                country: country,
                description: description,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a assessment cycle in status created.
    static func newAssessmentCycle(_ code: String, title: String) -> AssessmentCycle {
        return AssessmentCycle(
            code: code,
            title: title,
            durationMinutes: 0,
            country: "",
            description: "",
            minimum: 0.0,
            status: AssessmentCycleStatus.created
        )
    }
}
