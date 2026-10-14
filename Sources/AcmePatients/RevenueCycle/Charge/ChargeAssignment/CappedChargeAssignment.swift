import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped charge assignment is in its life cycle.
    enum CappedChargeAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped charge assignment as the charge team keeps it.
    final class CappedChargeAssignment {
        var code: String
        var label: String
        var createdAt: Int
        var cost: Double
        var active: Bool
        var acuity: Int
        var weight: Double
        var visible: Bool
        var pinned: Bool
        var copay: Double
        var ownerID: String
        var status: CappedChargeAssignmentStatus

        init(code: String, label: String, createdAt: Int, cost: Double, active: Bool, acuity: Int, weight: Double, visible: Bool, pinned: Bool, copay: Double, ownerID: String, status: CappedChargeAssignmentStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.cost = cost
            self.active = active
            self.acuity = acuity
            self.weight = weight
            self.visible = visible
            self.pinned = pinned
            self.copay = copay
            self.ownerID = ownerID
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

        func canMoveTo(_ next: CappedChargeAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CappedChargeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped charge assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return (cost * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> CappedChargeAssignment {
            return CappedChargeAssignment(
                code: code,
                label: label,
                createdAt: createdAt,
                cost: cost,
                active: active,
                acuity: acuity,
                weight: weight,
                visible: visible,
                pinned: pinned,
                copay: copay,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped charge assignment in status requested.
    static func newCappedChargeAssignment(_ code: String, label: String) -> CappedChargeAssignment {
        return CappedChargeAssignment(
            code: code,
            label: label,
            createdAt: 0,
            cost: 0.0,
            active: false,
            acuity: 0,
            weight: 0.0,
            visible: false,
            pinned: false,
            copay: 0.0,
            ownerID: "",
            status: CappedChargeAssignmentStatus.requested
        )
    }
}
