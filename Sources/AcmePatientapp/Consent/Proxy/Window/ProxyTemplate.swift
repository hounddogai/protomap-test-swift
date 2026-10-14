import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy template is in its life cycle.
    enum ProxyTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One proxy template, with what the planners need to act on it.
    final class ProxyTemplate {
        var code: String
        var title: String
        var version: Int
        var diagnosisCode: String
        var archived: Bool
        var status: ProxyTemplateStatus

        init(code: String, title: String, version: Int, diagnosisCode: String, archived: Bool, status: ProxyTemplateStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.diagnosisCode = diagnosisCode
            self.archived = archived
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

        func canMoveTo(_ next: ProxyTemplateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ProxyTemplateStatus.revoked
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

        func moveTo(_ next: ProxyTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> ProxyTemplate {
            return ProxyTemplate(
                code: code,
                title: title,
                version: version,
                diagnosisCode: diagnosisCode,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a proxy template in status requested.
    static func newProxyTemplate(_ code: String, title: String) -> ProxyTemplate {
        return ProxyTemplate(
            code: code,
            title: title,
            version: 0,
            diagnosisCode: "",
            archived: false,
            status: ProxyTemplateStatus.requested
        )
    }
}
