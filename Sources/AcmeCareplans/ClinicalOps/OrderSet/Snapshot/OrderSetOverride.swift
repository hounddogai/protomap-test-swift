import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set override is in its life cycle.
    enum OrderSetOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a order set override and its current status.
    final class OrderSetOverride {
        var code: String
        var label: String
        var diagnosisCode: String
        var tags: [String]
        var ceiling: Double
        var amount: Double
        var maximum: Double
        var status: OrderSetOverrideStatus

        init(code: String, label: String, diagnosisCode: String, tags: [String], ceiling: Double, amount: Double, maximum: Double, status: OrderSetOverrideStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.tags = tags
            self.ceiling = ceiling
            self.amount = amount
            self.maximum = maximum
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

        func canMoveTo(_ next: OrderSetOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == OrderSetOverrideStatus.pending
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == OrderSetOverrideStatus.suspended
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

        func moveTo(_ next: OrderSetOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((maximum + amount) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetOverride {
            return OrderSetOverride(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                tags: tags,
                ceiling: ceiling,
                amount: amount,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set override in status draft.
    static func newOrderSetOverride(_ code: String, label: String) -> OrderSetOverride {
        return OrderSetOverride(
            code: code,
            label: label,
            diagnosisCode: "",
            tags: [],
            ceiling: 0.0,
            amount: 0.0,
            maximum: 0.0,
            status: OrderSetOverrideStatus.draft
        )
    }
}
