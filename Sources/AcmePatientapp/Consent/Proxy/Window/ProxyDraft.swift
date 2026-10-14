import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy draft is in its life cycle.
    enum ProxyDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A proxy draft. Its code is unique within a tenant.
    final class ProxyDraft {
        var code: String
        var name: String
        var durationMinutes: Int
        var limit: Int
        var summary: String
        var ownerID: String
        var attempts: Int
        var payer: String
        var version: Int
        var budget: Double
        var visitMinutes: Int
        var status: ProxyDraftStatus

        init(code: String, name: String, durationMinutes: Int, limit: Int, summary: String, ownerID: String, attempts: Int, payer: String, version: Int, budget: Double, visitMinutes: Int, status: ProxyDraftStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.limit = limit
            self.summary = summary
            self.ownerID = ownerID
            self.attempts = attempts
            self.payer = payer
            self.version = version
            self.budget = budget
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: ProxyDraftStatus) -> Bool {
            switch status {
            case .created:
                return next == ProxyDraftStatus.validated || next == ProxyDraftStatus.retired
            case .validated:
                return next == ProxyDraftStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ProxyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((Double(durationMinutes) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyDraft {
            return ProxyDraft(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                limit: limit,
                summary: summary,
                ownerID: ownerID,
                attempts: attempts,
                payer: payer,
                version: version,
                budget: budget,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy draft in status created.
    static func newProxyDraft(_ code: String, name: String) -> ProxyDraft {
        return ProxyDraft(
            code: code,
            name: name,
            durationMinutes: 0,
            limit: 0,
            summary: "",
            ownerID: "",
            attempts: 0,
            payer: "",
            version: 0,
            budget: 0.0,
            visitMinutes: 0,
            status: ProxyDraftStatus.created
        )
    }
}
