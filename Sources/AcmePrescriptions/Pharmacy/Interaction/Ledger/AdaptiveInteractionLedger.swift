import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive interaction ledger is in its life cycle.
    enum AdaptiveInteractionLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive interaction ledger as the interaction team keeps it.
    final class AdaptiveInteractionLedger {
        var code: String
        var name: String
        var retries: Int
        var channel: String
        var archived: Bool
        var amount: Double
        var capacity: Int
        var acuity: Int
        var unit: String
        var floorValue: Double
        var allergy: String
        var status: AdaptiveInteractionLedgerStatus

        init(code: String, name: String, retries: Int, channel: String, archived: Bool, amount: Double, capacity: Int, acuity: Int, unit: String, floorValue: Double, allergy: String, status: AdaptiveInteractionLedgerStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.channel = channel
            self.archived = archived
            self.amount = amount
            self.capacity = capacity
            self.acuity = acuity
            self.unit = unit
            self.floorValue = floorValue
            self.allergy = allergy
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

        func canMoveTo(_ next: AdaptiveInteractionLedgerStatus) -> Bool {
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
                return next == AdaptiveInteractionLedgerStatus.archived
            case .resolved:
                return next == AdaptiveInteractionLedgerStatus.reopened
            case .reopened:
                return next == AdaptiveInteractionLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveInteractionLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive interaction ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive interaction ledger") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(acuity) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInteractionLedger {
            return AdaptiveInteractionLedger(
                code: code,
                name: name,
                retries: retries,
                channel: channel,
                archived: archived,
                amount: amount,
                capacity: capacity,
                acuity: acuity,
                unit: unit,
                floorValue: floorValue,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive interaction ledger in status open.
    static func newAdaptiveInteractionLedger(_ code: String, name: String) -> AdaptiveInteractionLedger {
        return AdaptiveInteractionLedger(
            code: code,
            name: name,
            retries: 0,
            channel: "",
            archived: false,
            amount: 0.0,
            capacity: 0,
            acuity: 0,
            unit: "",
            floorValue: 0.0,
            allergy: "",
            status: AdaptiveInteractionLedgerStatus.`open`
        )
    }
}
