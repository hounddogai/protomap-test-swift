import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility profile is in its life cycle.
    enum EligibilityProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A eligibility profile. Its code is unique within a tenant.
    final class EligibilityProfile {
        var code: String
        var label: String
        var amount: Double
        var patientRef: String
        var country: String
        var minimum: Double
        var locale: String
        var createdAt: Int
        var endsAt: Int
        var status: EligibilityProfileStatus

        init(code: String, label: String, amount: Double, patientRef: String, country: String, minimum: Double, locale: String, createdAt: Int, endsAt: Int, status: EligibilityProfileStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.patientRef = patientRef
            self.country = country
            self.minimum = minimum
            self.locale = locale
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == EligibilityProfileStatus.suspended || next == EligibilityProfileStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: EligibilityProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedLoad() -> Double {
            return (Double(endsAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> EligibilityProfile {
            return EligibilityProfile(
                code: code,
                label: label,
                amount: amount,
                patientRef: patientRef,
                country: country,
                minimum: minimum,
                locale: locale,
                createdAt: createdAt,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a eligibility profile in status draft.
    static func newEligibilityProfile(_ code: String, label: String) -> EligibilityProfile {
        return EligibilityProfile(
            code: code,
            label: label,
            amount: 0.0,
            patientRef: "",
            country: "",
            minimum: 0.0,
            locale: "",
            createdAt: 0,
            endsAt: 0,
            status: EligibilityProfileStatus.draft
        )
    }
}
