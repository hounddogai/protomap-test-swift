import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive specimen template is in its life cycle.
    enum AdaptiveSpecimenTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive specimen template. Its code is unique within a tenant.
    final class AdaptiveSpecimenTemplate {
        var code: String
        var title: String
        var visitMinutes: Int
        var specialty: String
        var procedureCode: String
        var revision: Int
        var patientRef: String
        var status: AdaptiveSpecimenTemplateStatus

        init(code: String, title: String, visitMinutes: Int, specialty: String, procedureCode: String, revision: Int, patientRef: String, status: AdaptiveSpecimenTemplateStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.revision = revision
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AdaptiveSpecimenTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == AdaptiveSpecimenTemplateStatus.draining || next == AdaptiveSpecimenTemplateStatus.stopped
            case .draining:
                return next == AdaptiveSpecimenTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSpecimenTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive specimen template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return (Double(revision) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveSpecimenTemplate {
            return AdaptiveSpecimenTemplate(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                specialty: specialty,
                procedureCode: procedureCode,
                revision: revision,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive specimen template in status idle.
    static func newAdaptiveSpecimenTemplate(_ code: String, title: String) -> AdaptiveSpecimenTemplate {
        return AdaptiveSpecimenTemplate(
            code: code,
            title: title,
            visitMinutes: 0,
            specialty: "",
            procedureCode: "",
            revision: 0,
            patientRef: "",
            status: AdaptiveSpecimenTemplateStatus.idle
        )
    }
}
