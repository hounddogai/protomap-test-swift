import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual eligibility manifest is in its life cycle.
    enum ManualEligibilityManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a manual eligibility manifest and its current status.
    final class ManualEligibilityManifest {
        var code: String
        var title: String
        var ward: String
        var amount: Double
        var minimum: Double
        var archived: Bool
        var status: ManualEligibilityManifestStatus

        init(code: String, title: String, ward: String, amount: Double, minimum: Double, archived: Bool, status: ManualEligibilityManifestStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.amount = amount
            self.minimum = minimum
            self.archived = archived
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

        func canMoveTo(_ next: ManualEligibilityManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualEligibilityManifestStatus.inReview || next == ManualEligibilityManifestStatus.resolved
            case .inReview:
                return next == ManualEligibilityManifestStatus.resolved || next == ManualEligibilityManifestStatus.archived
            case .resolved:
                return next == ManualEligibilityManifestStatus.archived
            case .reopened:
                return next == ManualEligibilityManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualEligibilityManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual eligibility manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual eligibility manifest") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((minimum + amount) * 100).rounded() / 100
        }

        func copyValue() -> ManualEligibilityManifest {
            return ManualEligibilityManifest(
                code: code,
                title: title,
                ward: ward,
                amount: amount,
                minimum: minimum,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual eligibility manifest in status open.
    static func newManualEligibilityManifest(_ code: String, title: String) -> ManualEligibilityManifest {
        return ManualEligibilityManifest(
            code: code,
            title: title,
            ward: "",
            amount: 0.0,
            minimum: 0.0,
            archived: false,
            status: ManualEligibilityManifestStatus.`open`
        )
    }
}
