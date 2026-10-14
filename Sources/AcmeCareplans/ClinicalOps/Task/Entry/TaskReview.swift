import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task review is in its life cycle.
    enum TaskReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A task review as the task team keeps it.
    final class TaskReview {
        var code: String
        var name: String
        var diagnosisCode: String
        var attributes: [String: String]
        var limit: Int
        var ownerID: String
        var category: String
        var refills: Int
        var archived: Bool
        var status: TaskReviewStatus

        init(code: String, name: String, diagnosisCode: String, attributes: [String: String], limit: Int, ownerID: String, category: String, refills: Int, archived: Bool, status: TaskReviewStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
            self.limit = limit
            self.ownerID = ownerID
            self.category = category
            self.refills = refills
            self.archived = archived
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

        func canMoveTo(_ next: TaskReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == TaskReviewStatus.stopped
            case .warming:
                return next == TaskReviewStatus.ready || next == TaskReviewStatus.stopped
            case .ready:
                return next == TaskReviewStatus.draining || next == TaskReviewStatus.stopped
            case .draining:
                return next == TaskReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("task review") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedTotal() -> Double {
            return ((Double(limit) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> TaskReview {
            return TaskReview(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                limit: limit,
                ownerID: ownerID,
                category: category,
                refills: refills,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a task review in status idle.
    static func newTaskReview(_ code: String, name: String) -> TaskReview {
        return TaskReview(
            code: code,
            name: name,
            diagnosisCode: "",
            attributes: [:],
            limit: 0,
            ownerID: "",
            category: "",
            refills: 0,
            archived: false,
            status: TaskReviewStatus.idle
        )
    }
}
