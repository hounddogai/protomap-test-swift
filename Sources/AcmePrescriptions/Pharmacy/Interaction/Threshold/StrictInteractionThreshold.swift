import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict interaction threshold is in its life cycle.
    enum StrictInteractionThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict interaction threshold. Its code is unique within a tenant.
    final class StrictInteractionThreshold {
        var code: String
        var name: String
        var reviewer: String
        var bed: String
        var pinned: Bool
        var capacity: Int
        var label: String
        var margin: Double
        var score: Double
        var weight: Double
        var amount: Double
        var status: StrictInteractionThresholdStatus

        init(code: String, name: String, reviewer: String, bed: String, pinned: Bool, capacity: Int, label: String, margin: Double, score: Double, weight: Double, amount: Double, status: StrictInteractionThresholdStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.bed = bed
            self.pinned = pinned
            self.capacity = capacity
            self.label = label
            self.margin = margin
            self.score = score
            self.weight = weight
            self.amount = amount
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

        func canMoveTo(_ next: StrictInteractionThresholdStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == StrictInteractionThresholdStatus.revoked || next == StrictInteractionThresholdStatus.expired
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

        func moveTo(_ next: StrictInteractionThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict interaction threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((weight + score) * 100).rounded() / 100
        }

        func copyValue() -> StrictInteractionThreshold {
            return StrictInteractionThreshold(
                code: code,
                name: name,
                reviewer: reviewer,
                bed: bed,
                pinned: pinned,
                capacity: capacity,
                label: label,
                margin: margin,
                score: score,
                weight: weight,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict interaction threshold in status requested.
    static func newStrictInteractionThreshold(_ code: String, name: String) -> StrictInteractionThreshold {
        return StrictInteractionThreshold(
            code: code,
            name: name,
            reviewer: "",
            bed: "",
            pinned: false,
            capacity: 0,
            label: "",
            margin: 0.0,
            score: 0.0,
            weight: 0.0,
            amount: 0.0,
            status: StrictInteractionThresholdStatus.requested
        )
    }
}
