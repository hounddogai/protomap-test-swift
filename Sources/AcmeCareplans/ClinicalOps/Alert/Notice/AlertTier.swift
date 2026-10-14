import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert tier is in its life cycle.
    enum AlertTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a alert tier and its current status.
    final class AlertTier {
        var code: String
        var name: String
        var weight: Double
        var pinned: Bool
        var threshold: Double
        var durationMinutes: Int
        var status: AlertTierStatus

        init(code: String, name: String, weight: Double, pinned: Bool, threshold: Double, durationMinutes: Int, status: AlertTierStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.pinned = pinned
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertTierStatus) -> Bool {
            switch status {
            case .created:
                return next == AlertTierStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AlertTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return (Double(durationMinutes) * weight * 100).rounded() / 100
        }

        func copyValue() -> AlertTier {
            return AlertTier(
                code: code,
                name: name,
                weight: weight,
                pinned: pinned,
                threshold: threshold,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a alert tier in status created.
    static func newAlertTier(_ code: String, name: String) -> AlertTier {
        return AlertTier(
            code: code,
            name: name,
            weight: 0.0,
            pinned: false,
            threshold: 0.0,
            durationMinutes: 0,
            status: AlertTierStatus.created
        )
    }
}
