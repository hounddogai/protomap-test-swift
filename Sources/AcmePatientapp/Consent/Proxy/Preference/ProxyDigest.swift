import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy digest is in its life cycle.
    enum ProxyDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One proxy digest, with what the planners need to act on it.
    final class ProxyDigest {
        var code: String
        var title: String
        var margin: Double
        var encounterID: String
        var payer: String
        var name: String
        var summary: String
        var contactEmail: String
        var phone: String
        var status: ProxyDigestStatus

        init(code: String, title: String, margin: Double, encounterID: String, payer: String, name: String, summary: String, contactEmail: String, phone: String, status: ProxyDigestStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.encounterID = encounterID
            self.payer = payer
            self.name = name
            self.summary = summary
            self.contactEmail = contactEmail
            self.phone = phone
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

        func canMoveTo(_ next: ProxyDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProxyDigestStatus.inReview || next == ProxyDigestStatus.reopened
            case .inReview:
                return next == ProxyDigestStatus.resolved || next == ProxyDigestStatus.archived
            case .resolved:
                return next == ProxyDigestStatus.reopened
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

        func moveTo(_ next: ProxyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> ProxyDigest {
            return ProxyDigest(
                code: code,
                title: title,
                margin: margin,
                encounterID: encounterID,
                payer: payer,
                name: name,
                summary: summary,
                contactEmail: contactEmail,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a proxy digest in status open.
    static func newProxyDigest(_ code: String, title: String) -> ProxyDigest {
        return ProxyDigest(
            code: code,
            title: title,
            margin: 0.0,
            encounterID: "",
            payer: "",
            name: "",
            summary: "",
            contactEmail: "",
            phone: "",
            status: ProxyDigestStatus.`open`
        )
    }
}
