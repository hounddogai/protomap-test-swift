import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual denial template is in its life cycle.
    enum ManualDenialTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual denial template. Its code is unique within a tenant.
    final class ManualDenialTemplate {
        var code: String
        var title: String
        var clinicianID: String
        var version: Int
        var procedureCode: String
        var visitMinutes: Int
        var bed: String
        var priority: Int
        var status: ManualDenialTemplateStatus

        init(code: String, title: String, clinicianID: String, version: Int, procedureCode: String, visitMinutes: Int, bed: String, priority: Int, status: ManualDenialTemplateStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.version = version
            self.procedureCode = procedureCode
            self.visitMinutes = visitMinutes
            self.bed = bed
            self.priority = priority
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

        func canMoveTo(_ next: ManualDenialTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
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
                switch next {
                case .archived:
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

        func moveTo(_ next: ManualDenialTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual denial template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return ((Double(priority) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ManualDenialTemplate {
            return ManualDenialTemplate(
                code: code,
                title: title,
                clinicianID: clinicianID,
                version: version,
                procedureCode: procedureCode,
                visitMinutes: visitMinutes,
                bed: bed,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual denial template in status open.
    static func newManualDenialTemplate(_ code: String, title: String) -> ManualDenialTemplate {
        return ManualDenialTemplate(
            code: code,
            title: title,
            clinicianID: "",
            version: 0,
            procedureCode: "",
            visitMinutes: 0,
            bed: "",
            priority: 0,
            status: ManualDenialTemplateStatus.`open`
        )
    }
}
