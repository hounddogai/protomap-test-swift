import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol plan is in its life cycle.
    enum CareProtocolPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One care protocol plan, with what the planners need to act on it.
    final class CareProtocolPlan {
        var code: String
        var name: String
        var pinned: Bool
        var discount: Double
        var version: Int
        var specialty: String
        var status: CareProtocolPlanStatus

        init(code: String, name: String, pinned: Bool, discount: Double, version: Int, specialty: String, status: CareProtocolPlanStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.discount = discount
            self.version = version
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

        func canMoveTo(_ next: CareProtocolPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareProtocolPlanStatus.revoked || next == CareProtocolPlanStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CareProtocolPlanStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return ((Double(version) - discount) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolPlan {
            return CareProtocolPlan(
                code: code,
                name: name,
                pinned: pinned,
                discount: discount,
                version: version,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol plan in status requested.
    static func newCareProtocolPlan(_ code: String, name: String) -> CareProtocolPlan {
        return CareProtocolPlan(
            code: code,
            name: name,
            pinned: false,
            discount: 0.0,
            version: 0,
            specialty: "",
            status: CareProtocolPlanStatus.requested
        )
    }
}
