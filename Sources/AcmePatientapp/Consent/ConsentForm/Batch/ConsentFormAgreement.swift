import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form agreement is in its life cycle.
    enum ConsentFormAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One consent form agreement, with what the planners need to act on it.
    final class ConsentFormAgreement {
        var code: String
        var name: String
        var country: String
        var phone: String
        var locale: String
        var retries: Int
        var ward: String
        var durationMinutes: Int
        var tags: [String]
        var notes: String
        var status: ConsentFormAgreementStatus

        init(code: String, name: String, country: String, phone: String, locale: String, retries: Int, ward: String, durationMinutes: Int, tags: [String], notes: String, status: ConsentFormAgreementStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.phone = phone
            self.locale = locale
            self.retries = retries
            self.ward = ward
            self.durationMinutes = durationMinutes
            self.tags = tags
            self.notes = notes
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

        func canMoveTo(_ next: ConsentFormAgreementStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ConsentFormAgreementStatus.published || next == ConsentFormAgreementStatus.retired
            case .published:
                return next == ConsentFormAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((Double(retries) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormAgreement {
            return ConsentFormAgreement(
                code: code,
                name: name,
                country: country,
                phone: phone,
                locale: locale,
                retries: retries,
                ward: ward,
                durationMinutes: durationMinutes,
                tags: tags,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a consent form agreement in status created.
    static func newConsentFormAgreement(_ code: String, name: String) -> ConsentFormAgreement {
        return ConsentFormAgreement(
            code: code,
            name: name,
            country: "",
            phone: "",
            locale: "",
            retries: 0,
            ward: "",
            durationMinutes: 0,
            tags: [],
            notes: "",
            status: ConsentFormAgreementStatus.created
        )
    }
}
