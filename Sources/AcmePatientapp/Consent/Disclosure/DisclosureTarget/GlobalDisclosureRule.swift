import AcmePlatform
import Foundation

extension Consent {
    /// Where a global disclosure rule is in its life cycle.
    enum GlobalDisclosureRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global disclosure rule as the disclosure team keeps it.
    final class GlobalDisclosureRule {
        var code: String
        var label: String
        var createdAt: Int
        var currency: String
        var dosageMg: Double
        var floorValue: Double
        var status: GlobalDisclosureRuleStatus

        init(code: String, label: String, createdAt: Int, currency: String, dosageMg: Double, floorValue: Double, status: GlobalDisclosureRuleStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.currency = currency
            self.dosageMg = dosageMg
            self.floorValue = floorValue
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

        func canMoveTo(_ next: GlobalDisclosureRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalDisclosureRuleStatus.queued || next == GlobalDisclosureRuleStatus.failed
            case .queued:
                return next == GlobalDisclosureRuleStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GlobalDisclosureRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDisclosureRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global disclosure rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global disclosure rule") \(code)"
        }

        func netExposure() -> Double {
            return ((floorValue + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDisclosureRule {
            return GlobalDisclosureRule(
                code: code,
                label: label,
                createdAt: createdAt,
                currency: currency,
                dosageMg: dosageMg,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global disclosure rule in status new.
    static func newGlobalDisclosureRule(_ code: String, label: String) -> GlobalDisclosureRule {
        return GlobalDisclosureRule(
            code: code,
            label: label,
            createdAt: 0,
            currency: "",
            dosageMg: 0.0,
            floorValue: 0.0,
            status: GlobalDisclosureRuleStatus.new
        )
    }
}
