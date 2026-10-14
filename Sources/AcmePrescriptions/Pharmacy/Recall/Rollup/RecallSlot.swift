import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall slot is in its life cycle.
    enum RecallSlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A recall slot. Its code is unique within a tenant.
    final class RecallSlot {
        var code: String
        var name: String
        var graceDays: Int
        var minimum: Double
        var amount: Double
        var floorValue: Double
        var ownerID: String
        var externalRef: String
        var status: RecallSlotStatus

        init(code: String, name: String, graceDays: Int, minimum: Double, amount: Double, floorValue: Double, ownerID: String, externalRef: String, status: RecallSlotStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.minimum = minimum
            self.amount = amount
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.externalRef = externalRef
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

        func canMoveTo(_ next: RecallSlotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RecallSlotStatus.inReview
            case .inReview:
                return next == RecallSlotStatus.resolved || next == RecallSlotStatus.reopened
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

        func moveTo(_ next: RecallSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return ((minimum + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RecallSlot {
            return RecallSlot(
                code: code,
                name: name,
                graceDays: graceDays,
                minimum: minimum,
                amount: amount,
                floorValue: floorValue,
                ownerID: ownerID,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall slot in status open.
    static func newRecallSlot(_ code: String, name: String) -> RecallSlot {
        return RecallSlot(
            code: code,
            name: name,
            graceDays: 0,
            minimum: 0.0,
            amount: 0.0,
            floorValue: 0.0,
            ownerID: "",
            externalRef: "",
            status: RecallSlotStatus.`open`
        )
    }
}
