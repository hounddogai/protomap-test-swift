import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness policy is in its life cycle.
    enum WitnessPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One witness policy, with what the planners need to act on it.
    final class WitnessPolicy {
        var code: String
        var label: String
        var ceiling: Double
        var category: String
        var allergy: String
        var discount: Double
        var batchSize: Int
        var status: WitnessPolicyStatus

        init(code: String, label: String, ceiling: Double, category: String, allergy: String, discount: Double, batchSize: Int, status: WitnessPolicyStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.category = category
            self.allergy = allergy
            self.discount = discount
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == WitnessPolicyStatus.active || next == WitnessPolicyStatus.suspended
            case .pending:
                return next == WitnessPolicyStatus.active
            case .active:
                return next == WitnessPolicyStatus.suspended || next == WitnessPolicyStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: WitnessPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveValue() -> Double {
            return ((ceiling + discount) * 100).rounded() / 100
        }

        func copyValue() -> WitnessPolicy {
            return WitnessPolicy(
                code: code,
                label: label,
                ceiling: ceiling,
                category: category,
                allergy: allergy,
                discount: discount,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a witness policy in status draft.
    static func newWitnessPolicy(_ code: String, label: String) -> WitnessPolicy {
        return WitnessPolicy(
            code: code,
            label: label,
            ceiling: 0.0,
            category: "",
            allergy: "",
            discount: 0.0,
            batchSize: 0,
            status: WitnessPolicyStatus.draft
        )
    }
}
