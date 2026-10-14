import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen slot is in its life cycle.
    enum SpecimenSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A specimen slot as the specimen team keeps it.
    final class SpecimenSlot {
        var code: String
        var label: String
        var retries: Int
        var limit: Int
        var budget: Double
        var maximum: Double
        var status: SpecimenSlotStatus

        init(code: String, label: String, retries: Int, limit: Int, budget: Double, maximum: Double, status: SpecimenSlotStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.limit = limit
            self.budget = budget
            self.maximum = maximum
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

        func canMoveTo(_ next: SpecimenSlotStatus) -> Bool {
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
                return next == SpecimenSlotStatus.expired
            case .revoked:
                return next == SpecimenSlotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((budget + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenSlot {
            return SpecimenSlot(
                code: code,
                label: label,
                retries: retries,
                limit: limit,
                budget: budget,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a specimen slot in status requested.
    static func newSpecimenSlot(_ code: String, label: String) -> SpecimenSlot {
        return SpecimenSlot(
            code: code,
            label: label,
            retries: 0,
            limit: 0,
            budget: 0.0,
            maximum: 0.0,
            status: SpecimenSlotStatus.requested
        )
    }
}
