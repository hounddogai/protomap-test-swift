import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift tier is in its life cycle.
    enum ShiftTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A shift tier as the shift team keeps it.
    final class ShiftTier {
        var code: String
        var name: String
        var durationMinutes: Int
        var externalRef: String
        var archived: Bool
        var minimum: Double
        var phone: String
        var refills: Int
        var status: ShiftTierStatus

        init(code: String, name: String, durationMinutes: Int, externalRef: String, archived: Bool, minimum: Double, phone: String, refills: Int, status: ShiftTierStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.externalRef = externalRef
            self.archived = archived
            self.minimum = minimum
            self.phone = phone
            self.refills = refills
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

        func canMoveTo(_ next: ShiftTierStatus) -> Bool {
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
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ShiftTierStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("shift tier") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(refills) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftTier {
            return ShiftTier(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                externalRef: externalRef,
                archived: archived,
                minimum: minimum,
                phone: phone,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a shift tier in status requested.
    static func newShiftTier(_ code: String, name: String) -> ShiftTier {
        return ShiftTier(
            code: code,
            name: name,
            durationMinutes: 0,
            externalRef: "",
            archived: false,
            minimum: 0.0,
            phone: "",
            refills: 0,
            status: ShiftTierStatus.requested
        )
    }
}
