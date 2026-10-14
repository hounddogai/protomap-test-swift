import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task estimate is in its life cycle.
    enum TaskEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a task estimate and its current status.
    final class TaskEstimate {
        var code: String
        var label: String
        var diagnosisCode: String
        var title: String
        var version: Int
        var updatedAt: Int
        var category: String
        var maximum: Double
        var ward: String
        var ratio: Double
        var amount: Double
        var status: TaskEstimateStatus

        init(code: String, label: String, diagnosisCode: String, title: String, version: Int, updatedAt: Int, category: String, maximum: Double, ward: String, ratio: Double, amount: Double, status: TaskEstimateStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.title = title
            self.version = version
            self.updatedAt = updatedAt
            self.category = category
            self.maximum = maximum
            self.ward = ward
            self.ratio = ratio
            self.amount = amount
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

        func canMoveTo(_ next: TaskEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == TaskEstimateStatus.suspended
            case .pending:
                return next == TaskEstimateStatus.suspended || next == TaskEstimateStatus.closed
            case .active:
                return next == TaskEstimateStatus.suspended || next == TaskEstimateStatus.closed
            case .suspended:
                return next == TaskEstimateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveValue() -> Double {
            return ((Double(version) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> TaskEstimate {
            return TaskEstimate(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                title: title,
                version: version,
                updatedAt: updatedAt,
                category: category,
                maximum: maximum,
                ward: ward,
                ratio: ratio,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a task estimate in status draft.
    static func newTaskEstimate(_ code: String, label: String) -> TaskEstimate {
        return TaskEstimate(
            code: code,
            label: label,
            diagnosisCode: "",
            title: "",
            version: 0,
            updatedAt: 0,
            category: "",
            maximum: 0.0,
            ward: "",
            ratio: 0.0,
            amount: 0.0,
            status: TaskEstimateStatus.draft
        )
    }
}
