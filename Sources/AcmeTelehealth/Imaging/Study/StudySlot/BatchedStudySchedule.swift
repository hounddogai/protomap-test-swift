import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched study schedule is in its life cycle.
    enum BatchedStudyScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A batched study schedule. Its code is unique within a tenant.
    final class BatchedStudySchedule {
        var code: String
        var name: String
        var approved: Bool
        var priority: Int
        var pinned: Bool
        var sequence: Int
        var ratio: Double
        var locale: String
        var reviewer: String
        var archived: Bool
        var status: BatchedStudyScheduleStatus

        init(code: String, name: String, approved: Bool, priority: Int, pinned: Bool, sequence: Int, ratio: Double, locale: String, reviewer: String, archived: Bool, status: BatchedStudyScheduleStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.priority = priority
            self.pinned = pinned
            self.sequence = sequence
            self.ratio = ratio
            self.locale = locale
            self.reviewer = reviewer
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedStudyScheduleStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedStudyScheduleStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == BatchedStudyScheduleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedStudyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched study schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched study schedule") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedStudySchedule {
            return BatchedStudySchedule(
                code: code,
                name: name,
                approved: approved,
                priority: priority,
                pinned: pinned,
                sequence: sequence,
                ratio: ratio,
                locale: locale,
                reviewer: reviewer,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a batched study schedule in status created.
    static func newBatchedStudySchedule(_ code: String, name: String) -> BatchedStudySchedule {
        return BatchedStudySchedule(
            code: code,
            name: name,
            approved: false,
            priority: 0,
            pinned: false,
            sequence: 0,
            ratio: 0.0,
            locale: "",
            reviewer: "",
            archived: false,
            status: BatchedStudyScheduleStatus.created
        )
    }
}
