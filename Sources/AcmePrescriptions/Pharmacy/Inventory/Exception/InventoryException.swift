import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory exception is in its life cycle.
    enum InventoryExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a inventory exception and its current status.
    final class InventoryException {
        var code: String
        var label: String
        var dosageMg: Double
        var priority: Int
        var description: String
        var attempts: Int
        var windowDays: Int
        var unit: String
        var status: InventoryExceptionStatus

        init(code: String, label: String, dosageMg: Double, priority: Int, description: String, attempts: Int, windowDays: Int, unit: String, status: InventoryExceptionStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.priority = priority
            self.description = description
            self.attempts = attempts
            self.windowDays = windowDays
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == InventoryExceptionStatus.resolved || next == InventoryExceptionStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: InventoryExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedVolume() -> Double {
            return ((dosageMg + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryException {
            return InventoryException(
                code: code,
                label: label,
                dosageMg: dosageMg,
                priority: priority,
                description: description,
                attempts: attempts,
                windowDays: windowDays,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a inventory exception in status open.
    static func newInventoryException(_ code: String, label: String) -> InventoryException {
        return InventoryException(
            code: code,
            label: label,
            dosageMg: 0.0,
            priority: 0,
            description: "",
            attempts: 0,
            windowDays: 0,
            unit: "",
            status: InventoryExceptionStatus.`open`
        )
    }
}
