import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy overtime snapshot is in its life cycle.
    enum LegacyOvertimeSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy overtime snapshot. Its code is unique within a tenant.
    final class LegacyOvertimeSnapshot {
        var code: String
        var title: String
        var graceDays: Int
        var bed: String
        var quantity: Int
        var category: String
        var tags: [String]
        var sequence: Int
        var source: String
        var visitMinutes: Int
        var status: LegacyOvertimeSnapshotStatus

        init(code: String, title: String, graceDays: Int, bed: String, quantity: Int, category: String, tags: [String], sequence: Int, source: String, visitMinutes: Int, status: LegacyOvertimeSnapshotStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.bed = bed
            self.quantity = quantity
            self.category = category
            self.tags = tags
            self.sequence = sequence
            self.source = source
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyOvertimeSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyOvertimeSnapshotStatus.inReview
            case .inReview:
                return next == LegacyOvertimeSnapshotStatus.resolved || next == LegacyOvertimeSnapshotStatus.archived
            case .resolved:
                return next == LegacyOvertimeSnapshotStatus.reopened || next == LegacyOvertimeSnapshotStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LegacyOvertimeSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy overtime snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((Double(visitMinutes) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyOvertimeSnapshot {
            return LegacyOvertimeSnapshot(
                code: code,
                title: title,
                graceDays: graceDays,
                bed: bed,
                quantity: quantity,
                category: category,
                tags: tags,
                sequence: sequence,
                source: source,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy overtime snapshot in status open.
    static func newLegacyOvertimeSnapshot(_ code: String, title: String) -> LegacyOvertimeSnapshot {
        return LegacyOvertimeSnapshot(
            code: code,
            title: title,
            graceDays: 0,
            bed: "",
            quantity: 0,
            category: "",
            tags: [],
            sequence: 0,
            source: "",
            visitMinutes: 0,
            status: LegacyOvertimeSnapshotStatus.`open`
        )
    }
}
