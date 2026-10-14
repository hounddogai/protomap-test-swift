import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory schedule is in its life cycle.
    enum InventoryScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a inventory schedule and its current status.
    final class InventorySchedule {
        var code: String
        var label: String
        var locale: String
        var unit: String
        var floorValue: Double
        var refills: Int
        var amount: Double
        var summary: String
        var copay: Double
        var updatedAt: Int
        var status: InventoryScheduleStatus

        init(code: String, label: String, locale: String, unit: String, floorValue: Double, refills: Int, amount: Double, summary: String, copay: Double, updatedAt: Int, status: InventoryScheduleStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.unit = unit
            self.floorValue = floorValue
            self.refills = refills
            self.amount = amount
            self.summary = summary
            self.copay = copay
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: InventoryScheduleStatus) -> Bool {
            switch status {
            case .draft:
                return next == InventoryScheduleStatus.pending || next == InventoryScheduleStatus.active
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == InventoryScheduleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("inventory schedule") \(code)"
        }

        func weightedTotal() -> Double {
            return ((amount - copay) * 100).rounded() / 100
        }

        func copyValue() -> InventorySchedule {
            return InventorySchedule(
                code: code,
                label: label,
                locale: locale,
                unit: unit,
                floorValue: floorValue,
                refills: refills,
                amount: amount,
                summary: summary,
                copay: copay,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a inventory schedule in status draft.
    static func newInventorySchedule(_ code: String, label: String) -> InventorySchedule {
        return InventorySchedule(
            code: code,
            label: label,
            locale: "",
            unit: "",
            floorValue: 0.0,
            refills: 0,
            amount: 0.0,
            summary: "",
            copay: 0.0,
            updatedAt: 0,
            status: InventoryScheduleStatus.draft
        )
    }
}
