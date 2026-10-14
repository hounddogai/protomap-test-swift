import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional claim bundle is in its life cycle.
    enum RegionalClaimBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional claim bundle as the claim team keeps it.
    final class RegionalClaimBundle {
        var code: String
        var label: String
        var minimum: Double
        var priority: Int
        var expiresAt: Int
        var retries: Int
        var endsAt: Int
        var capacity: Int
        var clinicianID: String
        var ratio: Double
        var status: RegionalClaimBundleStatus

        init(code: String, label: String, minimum: Double, priority: Int, expiresAt: Int, retries: Int, endsAt: Int, capacity: Int, clinicianID: String, ratio: Double, status: RegionalClaimBundleStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.priority = priority
            self.expiresAt = expiresAt
            self.retries = retries
            self.endsAt = endsAt
            self.capacity = capacity
            self.clinicianID = clinicianID
            self.ratio = ratio
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

        func canMoveTo(_ next: RegionalClaimBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalClaimBundleStatus.approved || next == RegionalClaimBundleStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RegionalClaimBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalClaimBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional claim bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return ((Double(retries) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalClaimBundle {
            return RegionalClaimBundle(
                code: code,
                label: label,
                minimum: minimum,
                priority: priority,
                expiresAt: expiresAt,
                retries: retries,
                endsAt: endsAt,
                capacity: capacity,
                clinicianID: clinicianID,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional claim bundle in status proposed.
    static func newRegionalClaimBundle(_ code: String, label: String) -> RegionalClaimBundle {
        return RegionalClaimBundle(
            code: code,
            label: label,
            minimum: 0.0,
            priority: 0,
            expiresAt: 0,
            retries: 0,
            endsAt: 0,
            capacity: 0,
            clinicianID: "",
            ratio: 0.0,
            status: RegionalClaimBundleStatus.proposed
        )
    }
}
