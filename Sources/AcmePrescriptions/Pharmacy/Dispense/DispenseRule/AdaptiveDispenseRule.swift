import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive dispense rule is in its life cycle.
    enum AdaptiveDispenseRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive dispense rule as the dispense team keeps it.
    final class AdaptiveDispenseRule {
        var code: String
        var title: String
        var notes: String
        var amount: Double
        var patientRef: String
        var category: String
        var ratio: Double
        var copay: Double
        var payer: String
        var timezone: String
        var status: AdaptiveDispenseRuleStatus

        init(code: String, title: String, notes: String, amount: Double, patientRef: String, category: String, ratio: Double, copay: Double, payer: String, timezone: String, status: AdaptiveDispenseRuleStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.amount = amount
            self.patientRef = patientRef
            self.category = category
            self.ratio = ratio
            self.copay = copay
            self.payer = payer
            self.timezone = timezone
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

        func canMoveTo(_ next: AdaptiveDispenseRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveDispenseRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive dispense rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return (amount * ratio * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDispenseRule {
            return AdaptiveDispenseRule(
                code: code,
                title: title,
                notes: notes,
                amount: amount,
                patientRef: patientRef,
                category: category,
                ratio: ratio,
                copay: copay,
                payer: payer,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive dispense rule in status new.
    static func newAdaptiveDispenseRule(_ code: String, title: String) -> AdaptiveDispenseRule {
        return AdaptiveDispenseRule(
            code: code,
            title: title,
            notes: "",
            amount: 0.0,
            patientRef: "",
            category: "",
            ratio: 0.0,
            copay: 0.0,
            payer: "",
            timezone: "",
            status: AdaptiveDispenseRuleStatus.new
        )
    }
}
