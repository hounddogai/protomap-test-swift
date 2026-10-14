import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap policy is in its life cycle.
    enum CareGapPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A care gap policy as the care gap team keeps it.
    final class CareGapPolicy {
        var code: String
        var title: String
        var specialty: String
        var ratio: Double
        var payer: String
        var active: Bool
        var status: CareGapPolicyStatus

        init(code: String, title: String, specialty: String, ratio: Double, payer: String, active: Bool, status: CareGapPolicyStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.ratio = ratio
            self.payer = payer
            self.active = active
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

        func canMoveTo(_ next: CareGapPolicyStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareGapPolicyStatus.revoked || next == CareGapPolicyStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CareGapPolicyStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> CareGapPolicy {
            return CareGapPolicy(
                code: code,
                title: title,
                specialty: specialty,
                ratio: ratio,
                payer: payer,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care gap policy in status requested.
    static func newCareGapPolicy(_ code: String, title: String) -> CareGapPolicy {
        return CareGapPolicy(
            code: code,
            title: title,
            specialty: "",
            ratio: 0.0,
            payer: "",
            active: false,
            status: CareGapPolicyStatus.requested
        )
    }
}
