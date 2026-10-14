import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive specimen schedule is in its life cycle.
    enum AdaptiveSpecimenScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive specimen schedule. Its code is unique within a tenant.
    final class AdaptiveSpecimenSchedule {
        var code: String
        var name: String
        var attempts: Int
        var procedureCode: String
        var category: String
        var locale: String
        var ceiling: Double
        var patientRef: String
        var windowDays: Int
        var description: String
        var revision: Int
        var status: AdaptiveSpecimenScheduleStatus

        init(code: String, name: String, attempts: Int, procedureCode: String, category: String, locale: String, ceiling: Double, patientRef: String, windowDays: Int, description: String, revision: Int, status: AdaptiveSpecimenScheduleStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.procedureCode = procedureCode
            self.category = category
            self.locale = locale
            self.ceiling = ceiling
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.description = description
            self.revision = revision
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

        func canMoveTo(_ next: AdaptiveSpecimenScheduleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AdaptiveSpecimenScheduleStatus.published || next == AdaptiveSpecimenScheduleStatus.retired
            case .published:
                return next == AdaptiveSpecimenScheduleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSpecimenScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive specimen schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveValue() -> Double {
            return ((Double(attempts) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveSpecimenSchedule {
            return AdaptiveSpecimenSchedule(
                code: code,
                name: name,
                attempts: attempts,
                procedureCode: procedureCode,
                category: category,
                locale: locale,
                ceiling: ceiling,
                patientRef: patientRef,
                windowDays: windowDays,
                description: description,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive specimen schedule in status created.
    static func newAdaptiveSpecimenSchedule(_ code: String, name: String) -> AdaptiveSpecimenSchedule {
        return AdaptiveSpecimenSchedule(
            code: code,
            name: name,
            attempts: 0,
            procedureCode: "",
            category: "",
            locale: "",
            ceiling: 0.0,
            patientRef: "",
            windowDays: 0,
            description: "",
            revision: 0,
            status: AdaptiveSpecimenScheduleStatus.created
        )
    }
}
