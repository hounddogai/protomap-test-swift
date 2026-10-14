import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement record is in its life cycle.
    enum StatementRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a statement record and its current status.
    final class StatementRecord {
        var code: String
        var title: String
        var bed: String
        var cost: Double
        var archived: Bool
        var segment: String
        var summary: String
        var margin: Double
        var country: String
        var notes: String
        var status: StatementRecordStatus

        init(code: String, title: String, bed: String, cost: Double, archived: Bool, segment: String, summary: String, margin: Double, country: String, notes: String, status: StatementRecordStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.cost = cost
            self.archived = archived
            self.segment = segment
            self.summary = summary
            self.margin = margin
            self.country = country
            self.notes = notes
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

        func canMoveTo(_ next: StatementRecordStatus) -> Bool {
            switch status {
            case .idle:
                return next == StatementRecordStatus.warming
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StatementRecordStatus.draining || next == StatementRecordStatus.stopped
            case .draining:
                return next == StatementRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedLoad() -> Double {
            return ((margin - cost) * 100).rounded() / 100
        }

        func copyValue() -> StatementRecord {
            return StatementRecord(
                code: code,
                title: title,
                bed: bed,
                cost: cost,
                archived: archived,
                segment: segment,
                summary: summary,
                margin: margin,
                country: country,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a statement record in status idle.
    static func newStatementRecord(_ code: String, title: String) -> StatementRecord {
        return StatementRecord(
            code: code,
            title: title,
            bed: "",
            cost: 0.0,
            archived: false,
            segment: "",
            summary: "",
            margin: 0.0,
            country: "",
            notes: "",
            status: StatementRecordStatus.idle
        )
    }
}
