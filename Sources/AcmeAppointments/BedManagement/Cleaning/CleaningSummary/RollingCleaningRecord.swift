import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling cleaning record is in its life cycle.
    enum RollingCleaningRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling cleaning record as the cleaning team keeps it.
    final class RollingCleaningRecord {
        var code: String
        var title: String
        var segment: String
        var score: Double
        var maximum: Double
        var ward: String
        var floorValue: Double
        var tags: [String]
        var summary: String
        var revision: Int
        var status: RollingCleaningRecordStatus

        init(code: String, title: String, segment: String, score: Double, maximum: Double, ward: String, floorValue: Double, tags: [String], summary: String, revision: Int, status: RollingCleaningRecordStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.score = score
            self.maximum = maximum
            self.ward = ward
            self.floorValue = floorValue
            self.tags = tags
            self.summary = summary
            self.revision = revision
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

        func canMoveTo(_ next: RollingCleaningRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingCleaningRecordStatus.scheduled
            case .scheduled:
                return next == RollingCleaningRecordStatus.completed || next == RollingCleaningRecordStatus.cancelled
            case .inProgress:
                return next == RollingCleaningRecordStatus.cancelled
            case .completed:
                return next == RollingCleaningRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCleaningRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling cleaning record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("rolling cleaning record") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return ((Double(revision) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RollingCleaningRecord {
            return RollingCleaningRecord(
                code: code,
                title: title,
                segment: segment,
                score: score,
                maximum: maximum,
                ward: ward,
                floorValue: floorValue,
                tags: tags,
                summary: summary,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling cleaning record in status planned.
    static func newRollingCleaningRecord(_ code: String, title: String) -> RollingCleaningRecord {
        return RollingCleaningRecord(
            code: code,
            title: title,
            segment: "",
            score: 0.0,
            maximum: 0.0,
            ward: "",
            floorValue: 0.0,
            tags: [],
            summary: "",
            revision: 0,
            status: RollingCleaningRecordStatus.planned
        )
    }
}
