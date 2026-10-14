import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy isolation segment is in its life cycle.
    enum LegacyIsolationSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy isolation segment. Its code is unique within a tenant.
    final class LegacyIsolationSegment {
        var code: String
        var title: String
        var source: String
        var summary: String
        var segment: String
        var bed: String
        var attempts: Int
        var category: String
        var limit: Int
        var clinicianID: String
        var status: LegacyIsolationSegmentStatus

        init(code: String, title: String, source: String, summary: String, segment: String, bed: String, attempts: Int, category: String, limit: Int, clinicianID: String, status: LegacyIsolationSegmentStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.summary = summary
            self.segment = segment
            self.bed = bed
            self.attempts = attempts
            self.category = category
            self.limit = limit
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyIsolationSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyIsolationSegmentStatus.pending || next == LegacyIsolationSegmentStatus.active
            case .pending:
                return next == LegacyIsolationSegmentStatus.suspended || next == LegacyIsolationSegmentStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == LegacyIsolationSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyIsolationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy isolation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveVolume() -> Double {
            return ((Double(limit) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyIsolationSegment {
            return LegacyIsolationSegment(
                code: code,
                title: title,
                source: source,
                summary: summary,
                segment: segment,
                bed: bed,
                attempts: attempts,
                category: category,
                limit: limit,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy isolation segment in status draft.
    static func newLegacyIsolationSegment(_ code: String, title: String) -> LegacyIsolationSegment {
        return LegacyIsolationSegment(
            code: code,
            title: title,
            source: "",
            summary: "",
            segment: "",
            bed: "",
            attempts: 0,
            category: "",
            limit: 0,
            clinicianID: "",
            status: LegacyIsolationSegmentStatus.draft
        )
    }
}
