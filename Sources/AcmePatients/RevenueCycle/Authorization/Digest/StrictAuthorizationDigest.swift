import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict authorization digest is in its life cycle.
    enum StrictAuthorizationDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict authorization digest. Its code is unique within a tenant.
    final class StrictAuthorizationDigest {
        var code: String
        var name: String
        var limit: Int
        var tags: [String]
        var priority: Int
        var dosageMg: Double
        var minimum: Double
        var phone: String
        var patientRef: String
        var locale: String
        var ward: String
        var status: StrictAuthorizationDigestStatus

        init(code: String, name: String, limit: Int, tags: [String], priority: Int, dosageMg: Double, minimum: Double, phone: String, patientRef: String, locale: String, ward: String, status: StrictAuthorizationDigestStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.tags = tags
            self.priority = priority
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.phone = phone
            self.patientRef = patientRef
            self.locale = locale
            self.ward = ward
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

        func canMoveTo(_ next: StrictAuthorizationDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StrictAuthorizationDigestStatus.retired
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

        func moveTo(_ next: StrictAuthorizationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict authorization digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((dosageMg - minimum) * 100).rounded() / 100
        }

        func copyValue() -> StrictAuthorizationDigest {
            return StrictAuthorizationDigest(
                code: code,
                name: name,
                limit: limit,
                tags: tags,
                priority: priority,
                dosageMg: dosageMg,
                minimum: minimum,
                phone: phone,
                patientRef: patientRef,
                locale: locale,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict authorization digest in status created.
    static func newStrictAuthorizationDigest(_ code: String, name: String) -> StrictAuthorizationDigest {
        return StrictAuthorizationDigest(
            code: code,
            name: name,
            limit: 0,
            tags: [],
            priority: 0,
            dosageMg: 0.0,
            minimum: 0.0,
            phone: "",
            patientRef: "",
            locale: "",
            ward: "",
            status: StrictAuthorizationDigestStatus.created
        )
    }
}
