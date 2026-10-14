import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance window is in its life cycle.
    enum RemittanceWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One remittance window, with what the planners need to act on it.
    final class RemittanceWindow {
        var code: String
        var title: String
        var ownerID: String
        var archived: Bool
        var amount: Double
        var windowDays: Int
        var category: String
        var unit: String
        var facility: String
        var status: RemittanceWindowStatus

        init(code: String, title: String, ownerID: String, archived: Bool, amount: Double, windowDays: Int, category: String, unit: String, facility: String, status: RemittanceWindowStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.archived = archived
            self.amount = amount
            self.windowDays = windowDays
            self.category = category
            self.unit = unit
            self.facility = facility
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

        func canMoveTo(_ next: RemittanceWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RemittanceWindowStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RemittanceWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netTotal() -> Double {
            return (Double(windowDays) * amount * 100).rounded() / 100
        }

        func copyValue() -> RemittanceWindow {
            return RemittanceWindow(
                code: code,
                title: title,
                ownerID: ownerID,
                archived: archived,
                amount: amount,
                windowDays: windowDays,
                category: category,
                unit: unit,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a remittance window in status planned.
    static func newRemittanceWindow(_ code: String, title: String) -> RemittanceWindow {
        return RemittanceWindow(
            code: code,
            title: title,
            ownerID: "",
            archived: false,
            amount: 0.0,
            windowDays: 0,
            category: "",
            unit: "",
            facility: "",
            status: RemittanceWindowStatus.planned
        )
    }
}
