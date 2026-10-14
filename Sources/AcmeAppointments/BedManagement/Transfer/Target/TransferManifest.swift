import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer manifest is in its life cycle.
    enum TransferManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One transfer manifest, with what the planners need to act on it.
    final class TransferManifest {
        var code: String
        var name: String
        var rate: Double
        var channel: String
        var encounterID: String
        var budget: Double
        var currency: String
        var procedureCode: String
        var acuity: Int
        var floorValue: Double
        var capacity: Int
        var status: TransferManifestStatus

        init(code: String, name: String, rate: Double, channel: String, encounterID: String, budget: Double, currency: String, procedureCode: String, acuity: Int, floorValue: Double, capacity: Int, status: TransferManifestStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.channel = channel
            self.encounterID = encounterID
            self.budget = budget
            self.currency = currency
            self.procedureCode = procedureCode
            self.acuity = acuity
            self.floorValue = floorValue
            self.capacity = capacity
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

        func canMoveTo(_ next: TransferManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TransferManifestStatus.suspended
            case .active:
                return next == TransferManifestStatus.suspended || next == TransferManifestStatus.closed
            case .suspended:
                return next == TransferManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("transfer manifest") \(code)"
        }

        func netExposure() -> Double {
            return (Double(capacity) * budget * 100).rounded() / 100
        }

        func copyValue() -> TransferManifest {
            return TransferManifest(
                code: code,
                name: name,
                rate: rate,
                channel: channel,
                encounterID: encounterID,
                budget: budget,
                currency: currency,
                procedureCode: procedureCode,
                acuity: acuity,
                floorValue: floorValue,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a transfer manifest in status draft.
    static func newTransferManifest(_ code: String, name: String) -> TransferManifest {
        return TransferManifest(
            code: code,
            name: name,
            rate: 0.0,
            channel: "",
            encounterID: "",
            budget: 0.0,
            currency: "",
            procedureCode: "",
            acuity: 0,
            floorValue: 0.0,
            capacity: 0,
            status: TransferManifestStatus.draft
        )
    }
}
