import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending alert ledger is in its life cycle.
    enum PendingAlertLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One pending alert ledger, with what the planners need to act on it.
    final class PendingAlertLedger {
        var code: String
        var title: String
        var patientRef: String
        var checksum: String
        var label: String
        var allergy: String
        var channel: String
        var limit: Int
        var category: String
        var attempts: Int
        var status: PendingAlertLedgerStatus

        init(code: String, title: String, patientRef: String, checksum: String, label: String, allergy: String, channel: String, limit: Int, category: String, attempts: Int, status: PendingAlertLedgerStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.checksum = checksum
            self.label = label
            self.allergy = allergy
            self.channel = channel
            self.limit = limit
            self.category = category
            self.attempts = attempts
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

        func canMoveTo(_ next: PendingAlertLedgerStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingAlertLedgerStatus.queued || next == PendingAlertLedgerStatus.failed
            case .queued:
                return next == PendingAlertLedgerStatus.running
            case .running:
                return next == PendingAlertLedgerStatus.done
            case .done:
                return next == PendingAlertLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingAlertLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending alert ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending alert ledger") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(limit) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> PendingAlertLedger {
            return PendingAlertLedger(
                code: code,
                title: title,
                patientRef: patientRef,
                checksum: checksum,
                label: label,
                allergy: allergy,
                channel: channel,
                limit: limit,
                category: category,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending alert ledger in status new.
    static func newPendingAlertLedger(_ code: String, title: String) -> PendingAlertLedger {
        return PendingAlertLedger(
            code: code,
            title: title,
            patientRef: "",
            checksum: "",
            label: "",
            allergy: "",
            channel: "",
            limit: 0,
            category: "",
            attempts: 0,
            status: PendingAlertLedgerStatus.new
        )
    }
}
