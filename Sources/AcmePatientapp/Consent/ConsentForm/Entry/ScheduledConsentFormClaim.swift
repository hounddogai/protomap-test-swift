import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled consent form claim is in its life cycle.
    enum ScheduledConsentFormClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a scheduled consent form claim and its current status.
    final class ScheduledConsentFormClaim {
        var code: String
        var title: String
        var minimum: Double
        var reviewer: String
        var diagnosisCode: String
        var pinned: Bool
        var name: String
        var copay: Double
        var encounterID: String
        var startsAt: Int
        var quantity: Int
        var status: ScheduledConsentFormClaimStatus

        init(code: String, title: String, minimum: Double, reviewer: String, diagnosisCode: String, pinned: Bool, name: String, copay: Double, encounterID: String, startsAt: Int, quantity: Int, status: ScheduledConsentFormClaimStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.reviewer = reviewer
            self.diagnosisCode = diagnosisCode
            self.pinned = pinned
            self.name = name
            self.copay = copay
            self.encounterID = encounterID
            self.startsAt = startsAt
            self.quantity = quantity
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

        func canMoveTo(_ next: ScheduledConsentFormClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledConsentFormClaimStatus.approved || next == ScheduledConsentFormClaimStatus.rejected
            case .approved:
                return next == ScheduledConsentFormClaimStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledConsentFormClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled consent form claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedVolume() -> Double {
            return (Double(quantity) * minimum * 100).rounded() / 100
        }

        func copyValue() -> ScheduledConsentFormClaim {
            return ScheduledConsentFormClaim(
                code: code,
                title: title,
                minimum: minimum,
                reviewer: reviewer,
                diagnosisCode: diagnosisCode,
                pinned: pinned,
                name: name,
                copay: copay,
                encounterID: encounterID,
                startsAt: startsAt,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled consent form claim in status proposed.
    static func newScheduledConsentFormClaim(_ code: String, title: String) -> ScheduledConsentFormClaim {
        return ScheduledConsentFormClaim(
            code: code,
            title: title,
            minimum: 0.0,
            reviewer: "",
            diagnosisCode: "",
            pinned: false,
            name: "",
            copay: 0.0,
            encounterID: "",
            startsAt: 0,
            quantity: 0,
            status: ScheduledConsentFormClaimStatus.proposed
        )
    }
}
