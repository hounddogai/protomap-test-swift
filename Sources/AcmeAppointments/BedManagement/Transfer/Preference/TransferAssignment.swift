import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer assignment is in its life cycle.
    enum TransferAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a transfer assignment and its current status.
    final class TransferAssignment {
        var code: String
        var label: String
        var payer: String
        var summary: String
        var acuity: Int
        var floorValue: Double
        var expiresAt: Int
        var encounterID: String
        var endsAt: Int
        var title: String
        var region: String
        var status: TransferAssignmentStatus

        init(code: String, label: String, payer: String, summary: String, acuity: Int, floorValue: Double, expiresAt: Int, encounterID: String, endsAt: Int, title: String, region: String, status: TransferAssignmentStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.summary = summary
            self.acuity = acuity
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.title = title
            self.region = region
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

        func canMoveTo(_ next: TransferAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TransferAssignmentStatus.approved || next == TransferAssignmentStatus.rejected
            case .approved:
                return next == TransferAssignmentStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: TransferAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("transfer assignment") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(expiresAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> TransferAssignment {
            return TransferAssignment(
                code: code,
                label: label,
                payer: payer,
                summary: summary,
                acuity: acuity,
                floorValue: floorValue,
                expiresAt: expiresAt,
                encounterID: encounterID,
                endsAt: endsAt,
                title: title,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a transfer assignment in status proposed.
    static func newTransferAssignment(_ code: String, label: String) -> TransferAssignment {
        return TransferAssignment(
            code: code,
            label: label,
            payer: "",
            summary: "",
            acuity: 0,
            floorValue: 0.0,
            expiresAt: 0,
            encounterID: "",
            endsAt: 0,
            title: "",
            region: "",
            status: TransferAssignmentStatus.proposed
        )
    }
}
