import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial agreement is in its life cycle.
    enum DenialAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A denial agreement as the denial team keeps it.
    final class DenialAgreement {
        var code: String
        var title: String
        var ownerID: String
        var maximum: Double
        var clinicianID: String
        var encounterID: String
        var category: String
        var country: String
        var status: DenialAgreementStatus

        init(code: String, title: String, ownerID: String, maximum: Double, clinicianID: String, encounterID: String, category: String, country: String, status: DenialAgreementStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.maximum = maximum
            self.clinicianID = clinicianID
            self.encounterID = encounterID
            self.category = category
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialAgreementStatus) -> Bool {
            switch status {
            case .planned:
                return next == DenialAgreementStatus.scheduled
            case .scheduled:
                return next == DenialAgreementStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DenialAgreementStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> DenialAgreement {
            return DenialAgreement(
                code: code,
                title: title,
                ownerID: ownerID,
                maximum: maximum,
                clinicianID: clinicianID,
                encounterID: encounterID,
                category: category,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a denial agreement in status planned.
    static func newDenialAgreement(_ code: String, title: String) -> DenialAgreement {
        return DenialAgreement(
            code: code,
            title: title,
            ownerID: "",
            maximum: 0.0,
            clinicianID: "",
            encounterID: "",
            category: "",
            country: "",
            status: DenialAgreementStatus.planned
        )
    }
}
