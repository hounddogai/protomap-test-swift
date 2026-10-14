import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen template is in its life cycle.
    enum SpecimenTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A specimen template as the specimen team keeps it.
    final class SpecimenTemplate {
        var code: String
        var title: String
        var specialty: String
        var facility: String
        var startsAt: Int
        var ward: String
        var visitMinutes: Int
        var revision: Int
        var procedureCode: String
        var encounterID: String
        var status: SpecimenTemplateStatus

        init(code: String, title: String, specialty: String, facility: String, startsAt: Int, ward: String, visitMinutes: Int, revision: Int, procedureCode: String, encounterID: String, status: SpecimenTemplateStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.facility = facility
            self.startsAt = startsAt
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.revision = revision
            self.procedureCode = procedureCode
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SpecimenTemplateStatus.done || next == SpecimenTemplateStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SpecimenTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("specimen template") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(revision) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenTemplate {
            return SpecimenTemplate(
                code: code,
                title: title,
                specialty: specialty,
                facility: facility,
                startsAt: startsAt,
                ward: ward,
                visitMinutes: visitMinutes,
                revision: revision,
                procedureCode: procedureCode,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a specimen template in status new.
    static func newSpecimenTemplate(_ code: String, title: String) -> SpecimenTemplate {
        return SpecimenTemplate(
            code: code,
            title: title,
            specialty: "",
            facility: "",
            startsAt: 0,
            ward: "",
            visitMinutes: 0,
            revision: 0,
            procedureCode: "",
            encounterID: "",
            status: SpecimenTemplateStatus.new
        )
    }
}
