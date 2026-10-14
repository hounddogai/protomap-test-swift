import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach ledger is in its life cycle.
    enum OutreachLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a outreach ledger and its current status.
    final class OutreachLedger {
        var code: String
        var label: String
        var createdAt: Int
        var externalRef: String
        var active: Bool
        var sequence: Int
        var weight: Double
        var refills: Int
        var channel: String
        var copay: Double
        var patientRef: String
        var status: OutreachLedgerStatus

        init(code: String, label: String, createdAt: Int, externalRef: String, active: Bool, sequence: Int, weight: Double, refills: Int, channel: String, copay: Double, patientRef: String, status: OutreachLedgerStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.active = active
            self.sequence = sequence
            self.weight = weight
            self.refills = refills
            self.channel = channel
            self.copay = copay
            self.patientRef = patientRef
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

        func canMoveTo(_ next: OutreachLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == OutreachLedgerStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: OutreachLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return ((Double(sequence) - weight) * 100).rounded() / 100
        }

        func copyValue() -> OutreachLedger {
            return OutreachLedger(
                code: code,
                label: label,
                createdAt: createdAt,
                externalRef: externalRef,
                active: active,
                sequence: sequence,
                weight: weight,
                refills: refills,
                channel: channel,
                copay: copay,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a outreach ledger in status created.
    static func newOutreachLedger(_ code: String, label: String) -> OutreachLedger {
        return OutreachLedger(
            code: code,
            label: label,
            createdAt: 0,
            externalRef: "",
            active: false,
            sequence: 0,
            weight: 0.0,
            refills: 0,
            channel: "",
            copay: 0.0,
            patientRef: "",
            status: OutreachLedgerStatus.created
        )
    }
}
