import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict task variance is in its life cycle.
    enum StrictTaskVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict task variance. Its code is unique within a tenant.
    final class StrictTaskVariance {
        var code: String
        var name: String
        var rate: Double
        var checksum: String
        var externalRef: String
        var refills: Int
        var amount: Double
        var encounterID: String
        var batchSize: Int
        var minimum: Double
        var notes: String
        var status: StrictTaskVarianceStatus

        init(code: String, name: String, rate: Double, checksum: String, externalRef: String, refills: Int, amount: Double, encounterID: String, batchSize: Int, minimum: Double, notes: String, status: StrictTaskVarianceStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.checksum = checksum
            self.externalRef = externalRef
            self.refills = refills
            self.amount = amount
            self.encounterID = encounterID
            self.batchSize = batchSize
            self.minimum = minimum
            self.notes = notes
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

        func canMoveTo(_ next: StrictTaskVarianceStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictTaskVarianceStatus.scheduled || next == StrictTaskVarianceStatus.cancelled
            case .scheduled:
                return next == StrictTaskVarianceStatus.inProgress
            case .inProgress:
                return next == StrictTaskVarianceStatus.completed || next == StrictTaskVarianceStatus.cancelled
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

        func moveTo(_ next: StrictTaskVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict task variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return ((Double(batchSize) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> StrictTaskVariance {
            return StrictTaskVariance(
                code: code,
                name: name,
                rate: rate,
                checksum: checksum,
                externalRef: externalRef,
                refills: refills,
                amount: amount,
                encounterID: encounterID,
                batchSize: batchSize,
                minimum: minimum,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict task variance in status planned.
    static func newStrictTaskVariance(_ code: String, name: String) -> StrictTaskVariance {
        return StrictTaskVariance(
            code: code,
            name: name,
            rate: 0.0,
            checksum: "",
            externalRef: "",
            refills: 0,
            amount: 0.0,
            encounterID: "",
            batchSize: 0,
            minimum: 0.0,
            notes: "",
            status: StrictTaskVarianceStatus.planned
        )
    }
}
