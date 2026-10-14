import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default discharge plan window is in its life cycle.
    enum DefaultDischargePlanWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default discharge plan window. Its code is unique within a tenant.
    final class DefaultDischargePlanWindow {
        var code: String
        var name: String
        var label: String
        var encounterID: String
        var title: String
        var category: String
        var amount: Double
        var status: DefaultDischargePlanWindowStatus

        init(code: String, name: String, label: String, encounterID: String, title: String, category: String, amount: Double, status: DefaultDischargePlanWindowStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.encounterID = encounterID
            self.title = title
            self.category = category
            self.amount = amount
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

        func canMoveTo(_ next: DefaultDischargePlanWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultDischargePlanWindowStatus.published
            case .validated:
                return next == DefaultDischargePlanWindowStatus.published || next == DefaultDischargePlanWindowStatus.retired
            case .published:
                return next == DefaultDischargePlanWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultDischargePlanWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default discharge plan window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> DefaultDischargePlanWindow {
            return DefaultDischargePlanWindow(
                code: code,
                name: name,
                label: label,
                encounterID: encounterID,
                title: title,
                category: category,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default discharge plan window in status created.
    static func newDefaultDischargePlanWindow(_ code: String, name: String) -> DefaultDischargePlanWindow {
        return DefaultDischargePlanWindow(
            code: code,
            name: name,
            label: "",
            encounterID: "",
            title: "",
            category: "",
            amount: 0.0,
            status: DefaultDischargePlanWindowStatus.created
        )
    }
}
