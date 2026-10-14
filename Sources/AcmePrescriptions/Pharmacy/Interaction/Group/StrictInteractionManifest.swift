import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict interaction manifest is in its life cycle.
    enum StrictInteractionManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a strict interaction manifest and its current status.
    final class StrictInteractionManifest {
        var code: String
        var label: String
        var acuity: Int
        var updatedAt: Int
        var amount: Double
        var active: Bool
        var status: StrictInteractionManifestStatus

        init(code: String, label: String, acuity: Int, updatedAt: Int, amount: Double, active: Bool, status: StrictInteractionManifestStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.amount = amount
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictInteractionManifestStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictInteractionManifestStatus.scheduled || next == StrictInteractionManifestStatus.cancelled
            case .scheduled:
                return next == StrictInteractionManifestStatus.completed || next == StrictInteractionManifestStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == StrictInteractionManifestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictInteractionManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict interaction manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(updatedAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> StrictInteractionManifest {
            return StrictInteractionManifest(
                code: code,
                label: label,
                acuity: acuity,
                updatedAt: updatedAt,
                amount: amount,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict interaction manifest in status planned.
    static func newStrictInteractionManifest(_ code: String, label: String) -> StrictInteractionManifest {
        return StrictInteractionManifest(
            code: code,
            label: label,
            acuity: 0,
            updatedAt: 0,
            amount: 0.0,
            active: false,
            status: StrictInteractionManifestStatus.planned
        )
    }
}
