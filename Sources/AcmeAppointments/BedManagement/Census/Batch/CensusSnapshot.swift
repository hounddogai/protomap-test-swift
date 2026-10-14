import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census snapshot is in its life cycle.
    enum CensusSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a census snapshot and its current status.
    final class CensusSnapshot {
        var code: String
        var label: String
        var visible: Bool
        var specialty: String
        var batchSize: Int
        var currency: String
        var summary: String
        var checksum: String
        var budget: Double
        var sequence: Int
        var status: CensusSnapshotStatus

        init(code: String, label: String, visible: Bool, specialty: String, batchSize: Int, currency: String, summary: String, checksum: String, budget: Double, sequence: Int, status: CensusSnapshotStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.specialty = specialty
            self.batchSize = batchSize
            self.currency = currency
            self.summary = summary
            self.checksum = checksum
            self.budget = budget
            self.sequence = sequence
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

        func canMoveTo(_ next: CensusSnapshotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CensusSnapshotStatus.failed
            case .done:
                return next == CensusSnapshotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("census snapshot") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(sequence) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> CensusSnapshot {
            return CensusSnapshot(
                code: code,
                label: label,
                visible: visible,
                specialty: specialty,
                batchSize: batchSize,
                currency: currency,
                summary: summary,
                checksum: checksum,
                budget: budget,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a census snapshot in status new.
    static func newCensusSnapshot(_ code: String, label: String) -> CensusSnapshot {
        return CensusSnapshot(
            code: code,
            label: label,
            visible: false,
            specialty: "",
            batchSize: 0,
            currency: "",
            summary: "",
            checksum: "",
            budget: 0.0,
            sequence: 0,
            status: CensusSnapshotStatus.new
        )
    }
}
