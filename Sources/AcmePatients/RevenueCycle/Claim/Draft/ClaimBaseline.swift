import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim baseline is in its life cycle.
    enum ClaimBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A claim baseline as the claim team keeps it.
    final class ClaimBaseline {
        var code: String
        var label: String
        var bed: String
        var copay: Double
        var clinicianID: String
        var specialty: String
        var status: ClaimBaselineStatus

        init(code: String, label: String, bed: String, copay: Double, clinicianID: String, specialty: String, status: ClaimBaselineStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.copay = copay
            self.clinicianID = clinicianID
            self.specialty = specialty
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

        func canMoveTo(_ next: ClaimBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == ClaimBaselineStatus.granted || next == ClaimBaselineStatus.revoked
            case .granted:
                return next == ClaimBaselineStatus.revoked
            case .revoked:
                return next == ClaimBaselineStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> ClaimBaseline {
            return ClaimBaseline(
                code: code,
                label: label,
                bed: bed,
                copay: copay,
                clinicianID: clinicianID,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim baseline in status requested.
    static func newClaimBaseline(_ code: String, label: String) -> ClaimBaseline {
        return ClaimBaseline(
            code: code,
            label: label,
            bed: "",
            copay: 0.0,
            clinicianID: "",
            specialty: "",
            status: ClaimBaselineStatus.requested
        )
    }
}
