import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot ledger is in its life cycle.
    enum SlotLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a slot ledger and its current status.
    final class SlotLedger {
        var code: String
        var name: String
        var patientRef: String
        var floorValue: Double
        var source: String
        var refills: Int
        var batchSize: Int
        var threshold: Double
        var specialty: String
        var pinned: Bool
        var status: SlotLedgerStatus

        init(code: String, name: String, patientRef: String, floorValue: Double, source: String, refills: Int, batchSize: Int, threshold: Double, specialty: String, pinned: Bool, status: SlotLedgerStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.source = source
            self.refills = refills
            self.batchSize = batchSize
            self.threshold = threshold
            self.specialty = specialty
            self.pinned = pinned
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

        func canMoveTo(_ next: SlotLedgerStatus) -> Bool {
            switch status {
            case .new:
                return next == SlotLedgerStatus.queued || next == SlotLedgerStatus.running
            case .queued:
                return next == SlotLedgerStatus.running || next == SlotLedgerStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SlotLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("slot ledger") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(batchSize) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> SlotLedger {
            return SlotLedger(
                code: code,
                name: name,
                patientRef: patientRef,
                floorValue: floorValue,
                source: source,
                refills: refills,
                batchSize: batchSize,
                threshold: threshold,
                specialty: specialty,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a slot ledger in status new.
    static func newSlotLedger(_ code: String, name: String) -> SlotLedger {
        return SlotLedger(
            code: code,
            name: name,
            patientRef: "",
            floorValue: 0.0,
            source: "",
            refills: 0,
            batchSize: 0,
            threshold: 0.0,
            specialty: "",
            pinned: false,
            status: SlotLedgerStatus.new
        )
    }
}
