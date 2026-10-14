import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol ledger is in its life cycle.
    enum CareProtocolLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a care protocol ledger and its current status.
    final class CareProtocolLedger {
        var code: String
        var label: String
        var createdAt: Int
        var endsAt: Int
        var externalRef: String
        var allergy: String
        var graceDays: Int
        var status: CareProtocolLedgerStatus

        init(code: String, label: String, createdAt: Int, endsAt: Int, externalRef: String, allergy: String, graceDays: Int, status: CareProtocolLedgerStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.allergy = allergy
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolLedgerStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolLedgerStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CareProtocolLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return (Double(endsAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolLedger {
            return CareProtocolLedger(
                code: code,
                label: label,
                createdAt: createdAt,
                endsAt: endsAt,
                externalRef: externalRef,
                allergy: allergy,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol ledger in status new.
    static func newCareProtocolLedger(_ code: String, label: String) -> CareProtocolLedger {
        return CareProtocolLedger(
            code: code,
            label: label,
            createdAt: 0,
            endsAt: 0,
            externalRef: "",
            allergy: "",
            graceDays: 0,
            status: CareProtocolLedgerStatus.new
        )
    }
}
