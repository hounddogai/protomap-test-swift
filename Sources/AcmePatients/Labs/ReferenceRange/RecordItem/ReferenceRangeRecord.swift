import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range record is in its life cycle.
    enum ReferenceRangeRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A reference range record as the reference range team keeps it.
    final class ReferenceRangeRecord {
        var code: String
        var name: String
        var revision: Int
        var minimum: Double
        var bed: String
        var status: ReferenceRangeRecordStatus

        init(code: String, name: String, revision: Int, minimum: Double, bed: String, status: ReferenceRangeRecordStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.minimum = minimum
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ReferenceRangeRecordStatus.draining
            case .ready:
                return next == ReferenceRangeRecordStatus.draining || next == ReferenceRangeRecordStatus.stopped
            case .draining:
                return next == ReferenceRangeRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return (minimum * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeRecord {
            return ReferenceRangeRecord(
                code: code,
                name: name,
                revision: revision,
                minimum: minimum,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a reference range record in status idle.
    static func newReferenceRangeRecord(_ code: String, name: String) -> ReferenceRangeRecord {
        return ReferenceRangeRecord(
            code: code,
            name: name,
            revision: 0,
            minimum: 0.0,
            bed: "",
            status: ReferenceRangeRecordStatus.idle
        )
    }
}
