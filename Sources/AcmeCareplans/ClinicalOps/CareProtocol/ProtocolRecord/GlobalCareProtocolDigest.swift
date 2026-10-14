import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global care protocol digest is in its life cycle.
    enum GlobalCareProtocolDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global care protocol digest. Its code is unique within a tenant.
    final class GlobalCareProtocolDigest {
        var code: String
        var title: String
        var acuity: Int
        var rate: Double
        var graceDays: Int
        var contactEmail: String
        var startsAt: Int
        var summary: String
        var status: GlobalCareProtocolDigestStatus

        init(code: String, title: String, acuity: Int, rate: Double, graceDays: Int, contactEmail: String, startsAt: Int, summary: String, status: GlobalCareProtocolDigestStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.rate = rate
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.startsAt = startsAt
            self.summary = summary
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

        func canMoveTo(_ next: GlobalCareProtocolDigestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
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
                return next == GlobalCareProtocolDigestStatus.draining || next == GlobalCareProtocolDigestStatus.stopped
            case .draining:
                return next == GlobalCareProtocolDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCareProtocolDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care protocol digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return (Double(startsAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareProtocolDigest {
            return GlobalCareProtocolDigest(
                code: code,
                title: title,
                acuity: acuity,
                rate: rate,
                graceDays: graceDays,
                contactEmail: contactEmail,
                startsAt: startsAt,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global care protocol digest in status idle.
    static func newGlobalCareProtocolDigest(_ code: String, title: String) -> GlobalCareProtocolDigest {
        return GlobalCareProtocolDigest(
            code: code,
            title: title,
            acuity: 0,
            rate: 0.0,
            graceDays: 0,
            contactEmail: "",
            startsAt: 0,
            summary: "",
            status: GlobalCareProtocolDigestStatus.idle
        )
    }
}
