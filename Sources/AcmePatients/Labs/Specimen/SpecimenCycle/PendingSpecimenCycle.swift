import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending specimen cycle is in its life cycle.
    enum PendingSpecimenCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One pending specimen cycle, with what the planners need to act on it.
    final class PendingSpecimenCycle {
        var code: String
        var label: String
        var expiresAt: Int
        var country: String
        var limit: Int
        var allergy: String
        var cost: Double
        var status: PendingSpecimenCycleStatus

        init(code: String, label: String, expiresAt: Int, country: String, limit: Int, allergy: String, cost: Double, status: PendingSpecimenCycleStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.country = country
            self.limit = limit
            self.allergy = allergy
            self.cost = cost
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

        func canMoveTo(_ next: PendingSpecimenCycleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PendingSpecimenCycleStatus.revoked || next == PendingSpecimenCycleStatus.expired
            case .revoked:
                return next == PendingSpecimenCycleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingSpecimenCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending specimen cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending specimen cycle") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(expiresAt) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> PendingSpecimenCycle {
            return PendingSpecimenCycle(
                code: code,
                label: label,
                expiresAt: expiresAt,
                country: country,
                limit: limit,
                allergy: allergy,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending specimen cycle in status requested.
    static func newPendingSpecimenCycle(_ code: String, label: String) -> PendingSpecimenCycle {
        return PendingSpecimenCycle(
            code: code,
            label: label,
            expiresAt: 0,
            country: "",
            limit: 0,
            allergy: "",
            cost: 0.0,
            status: PendingSpecimenCycleStatus.requested
        )
    }
}
