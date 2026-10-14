import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient language profile is in its life cycle.
    enum LenientLanguageProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient language profile as the language team keeps it.
    final class LenientLanguageProfile {
        var code: String
        var title: String
        var rate: Double
        var expiresAt: Int
        var windowDays: Int
        var contactEmail: String
        var dosageMg: Double
        var endsAt: Int
        var ownerID: String
        var region: String
        var limit: Int
        var status: LenientLanguageProfileStatus

        init(code: String, title: String, rate: Double, expiresAt: Int, windowDays: Int, contactEmail: String, dosageMg: Double, endsAt: Int, ownerID: String, region: String, limit: Int, status: LenientLanguageProfileStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.expiresAt = expiresAt
            self.windowDays = windowDays
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.endsAt = endsAt
            self.ownerID = ownerID
            self.region = region
            self.limit = limit
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

        func canMoveTo(_ next: LenientLanguageProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientLanguageProfileStatus.reopened
            case .inReview:
                return next == LenientLanguageProfileStatus.reopened || next == LenientLanguageProfileStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientLanguageProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientLanguageProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient language profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient language profile") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(expiresAt) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientLanguageProfile {
            return LenientLanguageProfile(
                code: code,
                title: title,
                rate: rate,
                expiresAt: expiresAt,
                windowDays: windowDays,
                contactEmail: contactEmail,
                dosageMg: dosageMg,
                endsAt: endsAt,
                ownerID: ownerID,
                region: region,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient language profile in status open.
    static func newLenientLanguageProfile(_ code: String, title: String) -> LenientLanguageProfile {
        return LenientLanguageProfile(
            code: code,
            title: title,
            rate: 0.0,
            expiresAt: 0,
            windowDays: 0,
            contactEmail: "",
            dosageMg: 0.0,
            endsAt: 0,
            ownerID: "",
            region: "",
            limit: 0,
            status: LenientLanguageProfileStatus.`open`
        )
    }
}
