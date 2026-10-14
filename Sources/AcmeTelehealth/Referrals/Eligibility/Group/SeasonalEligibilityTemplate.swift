import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal eligibility template is in its life cycle.
    enum SeasonalEligibilityTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal eligibility template. Its code is unique within a tenant.
    final class SeasonalEligibilityTemplate {
        var code: String
        var name: String
        var segment: String
        var contactEmail: String
        var facility: String
        var capacity: Int
        var sequence: Int
        var specialty: String
        var windowDays: Int
        var amount: Double
        var locale: String
        var status: SeasonalEligibilityTemplateStatus

        init(code: String, name: String, segment: String, contactEmail: String, facility: String, capacity: Int, sequence: Int, specialty: String, windowDays: Int, amount: Double, locale: String, status: SeasonalEligibilityTemplateStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.contactEmail = contactEmail
            self.facility = facility
            self.capacity = capacity
            self.sequence = sequence
            self.specialty = specialty
            self.windowDays = windowDays
            self.amount = amount
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalEligibilityTemplateStatus) -> Bool {
            switch status {
            case .requested:
                return next == SeasonalEligibilityTemplateStatus.revoked
            case .granted:
                return next == SeasonalEligibilityTemplateStatus.revoked || next == SeasonalEligibilityTemplateStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: SeasonalEligibilityTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal eligibility template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal eligibility template") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(sequence) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalEligibilityTemplate {
            return SeasonalEligibilityTemplate(
                code: code,
                name: name,
                segment: segment,
                contactEmail: contactEmail,
                facility: facility,
                capacity: capacity,
                sequence: sequence,
                specialty: specialty,
                windowDays: windowDays,
                amount: amount,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal eligibility template in status requested.
    static func newSeasonalEligibilityTemplate(_ code: String, name: String) -> SeasonalEligibilityTemplate {
        return SeasonalEligibilityTemplate(
            code: code,
            name: name,
            segment: "",
            contactEmail: "",
            facility: "",
            capacity: 0,
            sequence: 0,
            specialty: "",
            windowDays: 0,
            amount: 0.0,
            locale: "",
            status: SeasonalEligibilityTemplateStatus.requested
        )
    }
}
