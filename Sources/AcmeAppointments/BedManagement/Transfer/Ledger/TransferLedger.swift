import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer ledger is in its life cycle.
    enum TransferLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A transfer ledger. Its code is unique within a tenant.
    final class TransferLedger {
        var code: String
        var label: String
        var channel: String
        var ratio: Double
        var endsAt: Int
        var allergy: String
        var name: String
        var sequence: Int
        var source: String
        var status: TransferLedgerStatus

        init(code: String, label: String, channel: String, ratio: Double, endsAt: Int, allergy: String, name: String, sequence: Int, source: String, status: TransferLedgerStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.ratio = ratio
            self.endsAt = endsAt
            self.allergy = allergy
            self.name = name
            self.sequence = sequence
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferLedgerStatus) -> Bool {
            switch status {
            case .requested:
                return next == TransferLedgerStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TransferLedgerStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedExposure() -> Double {
            return (Double(sequence) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> TransferLedger {
            return TransferLedger(
                code: code,
                label: label,
                channel: channel,
                ratio: ratio,
                endsAt: endsAt,
                allergy: allergy,
                name: name,
                sequence: sequence,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a transfer ledger in status requested.
    static func newTransferLedger(_ code: String, label: String) -> TransferLedger {
        return TransferLedger(
            code: code,
            label: label,
            channel: "",
            ratio: 0.0,
            endsAt: 0,
            allergy: "",
            name: "",
            sequence: 0,
            source: "",
            status: TransferLedgerStatus.requested
        )
    }
}
