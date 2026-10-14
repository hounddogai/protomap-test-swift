import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool budget is in its life cycle.
    enum FloatPoolBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One float pool budget, with what the planners need to act on it.
    final class FloatPoolBudget {
        var code: String
        var label: String
        var approved: Bool
        var cost: Double
        var segment: String
        var capacity: Int
        var source: String
        var attributes: [String: String]
        var maximum: Double
        var externalRef: String
        var status: FloatPoolBudgetStatus

        init(code: String, label: String, approved: Bool, cost: Double, segment: String, capacity: Int, source: String, attributes: [String: String], maximum: Double, externalRef: String, status: FloatPoolBudgetStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.cost = cost
            self.segment = segment
            self.capacity = capacity
            self.source = source
            self.attributes = attributes
            self.maximum = maximum
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FloatPoolBudgetStatus.failed
            case .running:
                return next == FloatPoolBudgetStatus.done
            case .done:
                return next == FloatPoolBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveTotal() -> Double {
            return (maximum * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolBudget {
            return FloatPoolBudget(
                code: code,
                label: label,
                approved: approved,
                cost: cost,
                segment: segment,
                capacity: capacity,
                source: source,
                attributes: attributes,
                maximum: maximum,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a float pool budget in status new.
    static func newFloatPoolBudget(_ code: String, label: String) -> FloatPoolBudget {
        return FloatPoolBudget(
            code: code,
            label: label,
            approved: false,
            cost: 0.0,
            segment: "",
            capacity: 0,
            source: "",
            attributes: [:],
            maximum: 0.0,
            externalRef: "",
            status: FloatPoolBudgetStatus.new
        )
    }
}
