import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default assessment estimate is in its life cycle.
    enum DefaultAssessmentEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A default assessment estimate as the assessment team keeps it.
    final class DefaultAssessmentEstimate {
        var code: String
        var title: String
        var facility: String
        var procedureCode: String
        var ceiling: Double
        var specialty: String
        var attempts: Int
        var status: DefaultAssessmentEstimateStatus

        init(code: String, title: String, facility: String, procedureCode: String, ceiling: Double, specialty: String, attempts: Int, status: DefaultAssessmentEstimateStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.procedureCode = procedureCode
            self.ceiling = ceiling
            self.specialty = specialty
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultAssessmentEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == DefaultAssessmentEstimateStatus.active || next == DefaultAssessmentEstimateStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: DefaultAssessmentEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default assessment estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default assessment estimate") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((ceiling - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAssessmentEstimate {
            return DefaultAssessmentEstimate(
                code: code,
                title: title,
                facility: facility,
                procedureCode: procedureCode,
                ceiling: ceiling,
                specialty: specialty,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default assessment estimate in status draft.
    static func newDefaultAssessmentEstimate(_ code: String, title: String) -> DefaultAssessmentEstimate {
        return DefaultAssessmentEstimate(
            code: code,
            title: title,
            facility: "",
            procedureCode: "",
            ceiling: 0.0,
            specialty: "",
            attempts: 0,
            status: DefaultAssessmentEstimateStatus.draft
        )
    }
}
