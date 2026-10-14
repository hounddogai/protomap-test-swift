import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient census record is in its life cycle.
    enum LenientCensusRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One lenient census record, with what the planners need to act on it.
    final class LenientCensusRecord {
        var code: String
        var label: String
        var batchSize: Int
        var timezone: String
        var copay: Double
        var status: LenientCensusRecordStatus

        init(code: String, label: String, batchSize: Int, timezone: String, copay: Double, status: LenientCensusRecordStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.timezone = timezone
            self.copay = copay
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

        func canMoveTo(_ next: LenientCensusRecordStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LenientCensusRecordStatus.inProgress || next == LenientCensusRecordStatus.completed
            case .inProgress:
                return next == LenientCensusRecordStatus.completed
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

        func moveTo(_ next: LenientCensusRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient census record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((Double(batchSize) - copay) * 100).rounded() / 100
        }

        func copyValue() -> LenientCensusRecord {
            return LenientCensusRecord(
                code: code,
                label: label,
                batchSize: batchSize,
                timezone: timezone,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient census record in status planned.
    static func newLenientCensusRecord(_ code: String, label: String) -> LenientCensusRecord {
        return LenientCensusRecord(
            code: code,
            label: label,
            batchSize: 0,
            timezone: "",
            copay: 0.0,
            status: LenientCensusRecordStatus.planned
        )
    }
}
