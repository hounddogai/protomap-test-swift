import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility baseline is in its life cycle.
    enum EligibilityBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A eligibility baseline. Its code is unique within a tenant.
    final class EligibilityBaseline {
        var code: String
        var label: String
        var title: String
        var cost: Double
        var graceDays: Int
        var notes: String
        var active: Bool
        var batchSize: Int
        var version: Int
        var status: EligibilityBaselineStatus

        init(code: String, label: String, title: String, cost: Double, graceDays: Int, notes: String, active: Bool, batchSize: Int, version: Int, status: EligibilityBaselineStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.cost = cost
            self.graceDays = graceDays
            self.notes = notes
            self.active = active
            self.batchSize = batchSize
            self.version = version
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

        func canMoveTo(_ next: EligibilityBaselineStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == EligibilityBaselineStatus.revoked
            case .revoked:
                return next == EligibilityBaselineStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) - cost) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityBaseline {
            return EligibilityBaseline(
                code: code,
                label: label,
                title: title,
                cost: cost,
                graceDays: graceDays,
                notes: notes,
                active: active,
                batchSize: batchSize,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility baseline in status requested.
    static func newEligibilityBaseline(_ code: String, label: String) -> EligibilityBaseline {
        return EligibilityBaseline(
            code: code,
            label: label,
            title: "",
            cost: 0.0,
            graceDays: 0,
            notes: "",
            active: false,
            batchSize: 0,
            version: 0,
            status: EligibilityBaselineStatus.requested
        )
    }
}
