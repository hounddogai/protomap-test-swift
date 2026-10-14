import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped proxy exception is in its life cycle.
    enum CappedProxyExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a capped proxy exception and its current status.
    final class CappedProxyException {
        var code: String
        var name: String
        var reviewer: String
        var contactEmail: String
        var payer: String
        var bed: String
        var phone: String
        var version: Int
        var title: String
        var status: CappedProxyExceptionStatus

        init(code: String, name: String, reviewer: String, contactEmail: String, payer: String, bed: String, phone: String, version: Int, title: String, status: CappedProxyExceptionStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.contactEmail = contactEmail
            self.payer = payer
            self.bed = bed
            self.phone = phone
            self.version = version
            self.title = title
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

        func canMoveTo(_ next: CappedProxyExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CappedProxyExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped proxy exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("capped proxy exception") \(code)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> CappedProxyException {
            return CappedProxyException(
                code: code,
                name: name,
                reviewer: reviewer,
                contactEmail: contactEmail,
                payer: payer,
                bed: bed,
                phone: phone,
                version: version,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped proxy exception in status idle.
    static func newCappedProxyException(_ code: String, name: String) -> CappedProxyException {
        return CappedProxyException(
            code: code,
            name: name,
            reviewer: "",
            contactEmail: "",
            payer: "",
            bed: "",
            phone: "",
            version: 0,
            title: "",
            status: CappedProxyExceptionStatus.idle
        )
    }
}
