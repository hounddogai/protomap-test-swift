import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol template is in its life cycle.
    enum CareProtocolTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One care protocol template, with what the planners need to act on it.
    final class CareProtocolTemplate {
        var code: String
        var name: String
        var archived: Bool
        var version: Int
        var checksum: String
        var status: CareProtocolTemplateStatus

        init(code: String, name: String, archived: Bool, version: Int, checksum: String, status: CareProtocolTemplateStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.version = version
            self.checksum = checksum
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

        func canMoveTo(_ next: CareProtocolTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareProtocolTemplateStatus.active || next == CareProtocolTemplateStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CareProtocolTemplateStatus.closed
            case .suspended:
                return next == CareProtocolTemplateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> CareProtocolTemplate {
            return CareProtocolTemplate(
                code: code,
                name: name,
                archived: archived,
                version: version,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol template in status draft.
    static func newCareProtocolTemplate(_ code: String, name: String) -> CareProtocolTemplate {
        return CareProtocolTemplate(
            code: code,
            name: name,
            archived: false,
            version: 0,
            checksum: "",
            status: CareProtocolTemplateStatus.draft
        )
    }
}
