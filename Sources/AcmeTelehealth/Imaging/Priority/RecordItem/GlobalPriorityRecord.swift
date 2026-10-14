import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global priority record is in its life cycle.
    enum GlobalPriorityRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global priority record. Its code is unique within a tenant.
    final class GlobalPriorityRecord {
        var code: String
        var label: String
        var weight: Double
        var quantity: Int
        var notes: String
        var windowDays: Int
        var currency: String
        var cost: Double
        var endsAt: Int
        var attempts: Int
        var status: GlobalPriorityRecordStatus

        init(code: String, label: String, weight: Double, quantity: Int, notes: String, windowDays: Int, currency: String, cost: Double, endsAt: Int, attempts: Int, status: GlobalPriorityRecordStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.quantity = quantity
            self.notes = notes
            self.windowDays = windowDays
            self.currency = currency
            self.cost = cost
            self.endsAt = endsAt
            self.attempts = attempts
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

        func canMoveTo(_ next: GlobalPriorityRecordStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalPriorityRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global priority record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global priority record") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalPriorityRecord {
            return GlobalPriorityRecord(
                code: code,
                label: label,
                weight: weight,
                quantity: quantity,
                notes: notes,
                windowDays: windowDays,
                currency: currency,
                cost: cost,
                endsAt: endsAt,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global priority record in status open.
    static func newGlobalPriorityRecord(_ code: String, label: String) -> GlobalPriorityRecord {
        return GlobalPriorityRecord(
            code: code,
            label: label,
            weight: 0.0,
            quantity: 0,
            notes: "",
            windowDays: 0,
            currency: "",
            cost: 0.0,
            endsAt: 0,
            attempts: 0,
            status: GlobalPriorityRecordStatus.`open`
        )
    }
}
