import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol batch is in its life cycle.
    enum CareProtocolBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One care protocol batch, with what the planners need to act on it.
    final class CareProtocolBatch {
        var code: String
        var name: String
        var amount: Double
        var maximum: Double
        var clinicianID: String
        var checksum: String
        var margin: Double
        var floorValue: Double
        var minimum: Double
        var externalRef: String
        var score: Double
        var status: CareProtocolBatchStatus

        init(code: String, name: String, amount: Double, maximum: Double, clinicianID: String, checksum: String, margin: Double, floorValue: Double, minimum: Double, externalRef: String, score: Double, status: CareProtocolBatchStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.maximum = maximum
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.margin = margin
            self.floorValue = floorValue
            self.minimum = minimum
            self.externalRef = externalRef
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolBatchStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CareProtocolBatchStatus.rejected || next == CareProtocolBatchStatus.withdrawn
            case .rejected:
                return next == CareProtocolBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedLoad() -> Double {
            return (maximum * score * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolBatch {
            return CareProtocolBatch(
                code: code,
                name: name,
                amount: amount,
                maximum: maximum,
                clinicianID: clinicianID,
                checksum: checksum,
                margin: margin,
                floorValue: floorValue,
                minimum: minimum,
                externalRef: externalRef,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol batch in status proposed.
    static func newCareProtocolBatch(_ code: String, name: String) -> CareProtocolBatch {
        return CareProtocolBatch(
            code: code,
            name: name,
            amount: 0.0,
            maximum: 0.0,
            clinicianID: "",
            checksum: "",
            margin: 0.0,
            floorValue: 0.0,
            minimum: 0.0,
            externalRef: "",
            score: 0.0,
            status: CareProtocolBatchStatus.proposed
        )
    }
}
