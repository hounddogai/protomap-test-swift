import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility override is in its life cycle.
    enum EligibilityOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A eligibility override. Its code is unique within a tenant.
    final class EligibilityOverride {
        var code: String
        var title: String
        var ownerID: String
        var facility: String
        var ward: String
        var notes: String
        var summary: String
        var amount: Double
        var status: EligibilityOverrideStatus

        init(code: String, title: String, ownerID: String, facility: String, ward: String, notes: String, summary: String, amount: Double, status: EligibilityOverrideStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.facility = facility
            self.ward = ward
            self.notes = notes
            self.summary = summary
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityOverrideStatus) -> Bool {
            switch status {
            case .idle:
                return next == EligibilityOverrideStatus.ready
            case .warming:
                return next == EligibilityOverrideStatus.ready
            case .ready:
                return next == EligibilityOverrideStatus.draining || next == EligibilityOverrideStatus.stopped
            case .draining:
                return next == EligibilityOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> EligibilityOverride {
            return EligibilityOverride(
                code: code,
                title: title,
                ownerID: ownerID,
                facility: facility,
                ward: ward,
                notes: notes,
                summary: summary,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a eligibility override in status idle.
    static func newEligibilityOverride(_ code: String, title: String) -> EligibilityOverride {
        return EligibilityOverride(
            code: code,
            title: title,
            ownerID: "",
            facility: "",
            ward: "",
            notes: "",
            summary: "",
            amount: 0.0,
            status: EligibilityOverrideStatus.idle
        )
    }
}
