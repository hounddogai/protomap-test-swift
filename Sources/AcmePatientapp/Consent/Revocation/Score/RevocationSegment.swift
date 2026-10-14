import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation segment is in its life cycle.
    enum RevocationSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a revocation segment and its current status.
    final class RevocationSegment {
        var code: String
        var label: String
        var checksum: String
        var procedureCode: String
        var region: String
        var encounterID: String
        var minimum: Double
        var quantity: Int
        var currency: String
        var status: RevocationSegmentStatus

        init(code: String, label: String, checksum: String, procedureCode: String, region: String, encounterID: String, minimum: Double, quantity: Int, currency: String, status: RevocationSegmentStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.procedureCode = procedureCode
            self.region = region
            self.encounterID = encounterID
            self.minimum = minimum
            self.quantity = quantity
            self.currency = currency
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

        func canMoveTo(_ next: RevocationSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RevocationSegmentStatus.published
            case .validated:
                return next == RevocationSegmentStatus.published || next == RevocationSegmentStatus.retired
            case .published:
                return next == RevocationSegmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return ((minimum + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationSegment {
            return RevocationSegment(
                code: code,
                label: label,
                checksum: checksum,
                procedureCode: procedureCode,
                region: region,
                encounterID: encounterID,
                minimum: minimum,
                quantity: quantity,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a revocation segment in status created.
    static func newRevocationSegment(_ code: String, label: String) -> RevocationSegment {
        return RevocationSegment(
            code: code,
            label: label,
            checksum: "",
            procedureCode: "",
            region: "",
            encounterID: "",
            minimum: 0.0,
            quantity: 0,
            currency: "",
            status: RevocationSegmentStatus.created
        )
    }
}
