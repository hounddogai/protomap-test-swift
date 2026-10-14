import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form baseline is in its life cycle.
    enum ConsentFormBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a consent form baseline and its current status.
    final class ConsentFormBaseline {
        var code: String
        var name: String
        var checksum: String
        var minimum: Double
        var copay: Double
        var contactEmail: String
        var floorValue: Double
        var allergy: String
        var status: ConsentFormBaselineStatus

        init(code: String, name: String, checksum: String, minimum: Double, copay: Double, contactEmail: String, floorValue: Double, allergy: String, status: ConsentFormBaselineStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.minimum = minimum
            self.copay = copay
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.allergy = allergy
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

        func canMoveTo(_ next: ConsentFormBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ConsentFormBaselineStatus.inReview || next == ConsentFormBaselineStatus.archived
            case .inReview:
                return next == ConsentFormBaselineStatus.reopened || next == ConsentFormBaselineStatus.archived
            case .resolved:
                return next == ConsentFormBaselineStatus.reopened || next == ConsentFormBaselineStatus.archived
            case .reopened:
                return next == ConsentFormBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((floorValue + copay) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormBaseline {
            return ConsentFormBaseline(
                code: code,
                name: name,
                checksum: checksum,
                minimum: minimum,
                copay: copay,
                contactEmail: contactEmail,
                floorValue: floorValue,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a consent form baseline in status open.
    static func newConsentFormBaseline(_ code: String, name: String) -> ConsentFormBaseline {
        return ConsentFormBaseline(
            code: code,
            name: name,
            checksum: "",
            minimum: 0.0,
            copay: 0.0,
            contactEmail: "",
            floorValue: 0.0,
            allergy: "",
            status: ConsentFormBaselineStatus.`open`
        )
    }
}
