import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form override is in its life cycle.
    enum ConsentFormOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One consent form override, with what the planners need to act on it.
    final class ConsentFormOverride {
        var code: String
        var label: String
        var archived: Bool
        var country: String
        var clinicianID: String
        var acuity: Int
        var status: ConsentFormOverrideStatus

        init(code: String, label: String, archived: Bool, country: String, clinicianID: String, acuity: Int, status: ConsentFormOverrideStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.country = country
            self.clinicianID = clinicianID
            self.acuity = acuity
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

        func canMoveTo(_ next: ConsentFormOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ConsentFormOverrideStatus.reopened || next == ConsentFormOverrideStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ConsentFormOverrideStatus.reopened || next == ConsentFormOverrideStatus.archived
            case .reopened:
                return next == ConsentFormOverrideStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("consent form override") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> ConsentFormOverride {
            return ConsentFormOverride(
                code: code,
                label: label,
                archived: archived,
                country: country,
                clinicianID: clinicianID,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a consent form override in status open.
    static func newConsentFormOverride(_ code: String, label: String) -> ConsentFormOverride {
        return ConsentFormOverride(
            code: code,
            label: label,
            archived: false,
            country: "",
            clinicianID: "",
            acuity: 0,
            status: ConsentFormOverrideStatus.`open`
        )
    }
}
