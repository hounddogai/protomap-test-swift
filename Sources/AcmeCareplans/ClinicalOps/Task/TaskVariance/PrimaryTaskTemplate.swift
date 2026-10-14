import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary task template is in its life cycle.
    enum PrimaryTaskTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary task template as the task team keeps it.
    final class PrimaryTaskTemplate {
        var code: String
        var name: String
        var ownerID: String
        var checksum: String
        var ward: String
        var diagnosisCode: String
        var priority: Int
        var procedureCode: String
        var status: PrimaryTaskTemplateStatus

        init(code: String, name: String, ownerID: String, checksum: String, ward: String, diagnosisCode: String, priority: Int, procedureCode: String, status: PrimaryTaskTemplateStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.checksum = checksum
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryTaskTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryTaskTemplateStatus.reopened || next == PrimaryTaskTemplateStatus.archived
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PrimaryTaskTemplateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryTaskTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary task template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary task template") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> PrimaryTaskTemplate {
            return PrimaryTaskTemplate(
                code: code,
                name: name,
                ownerID: ownerID,
                checksum: checksum,
                ward: ward,
                diagnosisCode: diagnosisCode,
                priority: priority,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary task template in status open.
    static func newPrimaryTaskTemplate(_ code: String, name: String) -> PrimaryTaskTemplate {
        return PrimaryTaskTemplate(
            code: code,
            name: name,
            ownerID: "",
            checksum: "",
            ward: "",
            diagnosisCode: "",
            priority: 0,
            procedureCode: "",
            status: PrimaryTaskTemplateStatus.`open`
        )
    }
}
