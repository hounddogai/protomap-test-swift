import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive formulary override is in its life cycle.
    enum AdaptiveFormularyOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive formulary override. Its code is unique within a tenant.
    final class AdaptiveFormularyOverride {
        var code: String
        var label: String
        var quantity: Int
        var weight: Double
        var active: Bool
        var approved: Bool
        var description: String
        var durationMinutes: Int
        var rate: Double
        var status: AdaptiveFormularyOverrideStatus

        init(code: String, label: String, quantity: Int, weight: Double, active: Bool, approved: Bool, description: String, durationMinutes: Int, rate: Double, status: AdaptiveFormularyOverrideStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.weight = weight
            self.active = active
            self.approved = approved
            self.description = description
            self.durationMinutes = durationMinutes
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveFormularyOverrideStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == AdaptiveFormularyOverrideStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AdaptiveFormularyOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive formulary override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return (weight * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFormularyOverride {
            return AdaptiveFormularyOverride(
                code: code,
                label: label,
                quantity: quantity,
                weight: weight,
                active: active,
                approved: approved,
                description: description,
                durationMinutes: durationMinutes,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive formulary override in status idle.
    static func newAdaptiveFormularyOverride(_ code: String, label: String) -> AdaptiveFormularyOverride {
        return AdaptiveFormularyOverride(
            code: code,
            label: label,
            quantity: 0,
            weight: 0.0,
            active: false,
            approved: false,
            description: "",
            durationMinutes: 0,
            rate: 0.0,
            status: AdaptiveFormularyOverrideStatus.idle
        )
    }
}
