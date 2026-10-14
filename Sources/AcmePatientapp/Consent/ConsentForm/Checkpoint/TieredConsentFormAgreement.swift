import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered consent form agreement is in its life cycle.
    enum TieredConsentFormAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a tiered consent form agreement and its current status.
    final class TieredConsentFormAgreement {
        var code: String
        var name: String
        var durationMinutes: Int
        var checksum: String
        var createdAt: Int
        var currency: String
        var summary: String
        var specialty: String
        var reviewer: String
        var phone: String
        var status: TieredConsentFormAgreementStatus

        init(code: String, name: String, durationMinutes: Int, checksum: String, createdAt: Int, currency: String, summary: String, specialty: String, reviewer: String, phone: String, status: TieredConsentFormAgreementStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.checksum = checksum
            self.createdAt = createdAt
            self.currency = currency
            self.summary = summary
            self.specialty = specialty
            self.reviewer = reviewer
            self.phone = phone
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

        func canMoveTo(_ next: TieredConsentFormAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredConsentFormAgreementStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredConsentFormAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered consent form agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered consent form agreement") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(createdAt) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> TieredConsentFormAgreement {
            return TieredConsentFormAgreement(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                checksum: checksum,
                createdAt: createdAt,
                currency: currency,
                summary: summary,
                specialty: specialty,
                reviewer: reviewer,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered consent form agreement in status proposed.
    static func newTieredConsentFormAgreement(_ code: String, name: String) -> TieredConsentFormAgreement {
        return TieredConsentFormAgreement(
            code: code,
            name: name,
            durationMinutes: 0,
            checksum: "",
            createdAt: 0,
            currency: "",
            summary: "",
            specialty: "",
            reviewer: "",
            phone: "",
            status: TieredConsentFormAgreementStatus.proposed
        )
    }
}
