import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy variance is in its life cycle.
    enum LenientProxyVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient proxy variance. Its code is unique within a tenant.
    final class LenientProxyVariance {
        var code: String
        var name: String
        var ward: String
        var acuity: Int
        var channel: String
        var locale: String
        var procedureCode: String
        var rate: Double
        var contactEmail: String
        var source: String
        var version: Int
        var status: LenientProxyVarianceStatus

        init(code: String, name: String, ward: String, acuity: Int, channel: String, locale: String, procedureCode: String, rate: Double, contactEmail: String, source: String, version: Int, status: LenientProxyVarianceStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.acuity = acuity
            self.channel = channel
            self.locale = locale
            self.procedureCode = procedureCode
            self.rate = rate
            self.contactEmail = contactEmail
            self.source = source
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientProxyVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LenientProxyVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProxyVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedLoad() -> Double {
            return ((rate - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> LenientProxyVariance {
            return LenientProxyVariance(
                code: code,
                name: name,
                ward: ward,
                acuity: acuity,
                channel: channel,
                locale: locale,
                procedureCode: procedureCode,
                rate: rate,
                contactEmail: contactEmail,
                source: source,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient proxy variance in status proposed.
    static func newLenientProxyVariance(_ code: String, name: String) -> LenientProxyVariance {
        return LenientProxyVariance(
            code: code,
            name: name,
            ward: "",
            acuity: 0,
            channel: "",
            locale: "",
            procedureCode: "",
            rate: 0.0,
            contactEmail: "",
            source: "",
            version: 0,
            status: LenientProxyVarianceStatus.proposed
        )
    }
}
