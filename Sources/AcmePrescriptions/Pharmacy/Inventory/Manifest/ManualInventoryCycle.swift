import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual inventory cycle is in its life cycle.
    enum ManualInventoryCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual inventory cycle. Its code is unique within a tenant.
    final class ManualInventoryCycle {
        var code: String
        var label: String
        var region: String
        var summary: String
        var budget: Double
        var amount: Double
        var dosageMg: Double
        var phone: String
        var contactEmail: String
        var status: ManualInventoryCycleStatus

        init(code: String, label: String, region: String, summary: String, budget: Double, amount: Double, dosageMg: Double, phone: String, contactEmail: String, status: ManualInventoryCycleStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.summary = summary
            self.budget = budget
            self.amount = amount
            self.dosageMg = dosageMg
            self.phone = phone
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ManualInventoryCycleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ManualInventoryCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual inventory cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual inventory cycle") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((dosageMg - amount) * 100).rounded() / 100
        }

        func copyValue() -> ManualInventoryCycle {
            return ManualInventoryCycle(
                code: code,
                label: label,
                region: region,
                summary: summary,
                budget: budget,
                amount: amount,
                dosageMg: dosageMg,
                phone: phone,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual inventory cycle in status planned.
    static func newManualInventoryCycle(_ code: String, label: String) -> ManualInventoryCycle {
        return ManualInventoryCycle(
            code: code,
            label: label,
            region: "",
            summary: "",
            budget: 0.0,
            amount: 0.0,
            dosageMg: 0.0,
            phone: "",
            contactEmail: "",
            status: ManualInventoryCycleStatus.planned
        )
    }
}
