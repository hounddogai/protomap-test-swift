import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive credential template is in its life cycle.
    enum AdaptiveCredentialTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive credential template. Its code is unique within a tenant.
    final class AdaptiveCredentialTemplate {
        var code: String
        var name: String
        var endsAt: Int
        var archived: Bool
        var summary: String
        var bed: String
        var status: AdaptiveCredentialTemplateStatus

        init(code: String, name: String, endsAt: Int, archived: Bool, summary: String, bed: String, status: AdaptiveCredentialTemplateStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.archived = archived
            self.summary = summary
            self.bed = bed
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

        func canMoveTo(_ next: AdaptiveCredentialTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == AdaptiveCredentialTemplateStatus.ready
            case .warming:
                return next == AdaptiveCredentialTemplateStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AdaptiveCredentialTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCredentialTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive credential template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> AdaptiveCredentialTemplate {
            return AdaptiveCredentialTemplate(
                code: code,
                name: name,
                endsAt: endsAt,
                archived: archived,
                summary: summary,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive credential template in status idle.
    static func newAdaptiveCredentialTemplate(_ code: String, name: String) -> AdaptiveCredentialTemplate {
        return AdaptiveCredentialTemplate(
            code: code,
            name: name,
            endsAt: 0,
            archived: false,
            summary: "",
            bed: "",
            status: AdaptiveCredentialTemplateStatus.idle
        )
    }
}
