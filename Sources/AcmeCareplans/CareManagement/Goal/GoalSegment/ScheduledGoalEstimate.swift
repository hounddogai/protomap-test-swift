import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled goal estimate is in its life cycle.
    enum ScheduledGoalEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled goal estimate. Its code is unique within a tenant.
    final class ScheduledGoalEstimate {
        var code: String
        var name: String
        var archived: Bool
        var region: String
        var dosageMg: Double
        var category: String
        var batchSize: Int
        var reviewer: String
        var locale: String
        var externalRef: String
        var visible: Bool
        var status: ScheduledGoalEstimateStatus

        init(code: String, name: String, archived: Bool, region: String, dosageMg: Double, category: String, batchSize: Int, reviewer: String, locale: String, externalRef: String, visible: Bool, status: ScheduledGoalEstimateStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.region = region
            self.dosageMg = dosageMg
            self.category = category
            self.batchSize = batchSize
            self.reviewer = reviewer
            self.locale = locale
            self.externalRef = externalRef
            self.visible = visible
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

        func canMoveTo(_ next: ScheduledGoalEstimateStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledGoalEstimateStatus.published
            case .validated:
                return next == ScheduledGoalEstimateStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ScheduledGoalEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled goal estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return ((Double(batchSize) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledGoalEstimate {
            return ScheduledGoalEstimate(
                code: code,
                name: name,
                archived: archived,
                region: region,
                dosageMg: dosageMg,
                category: category,
                batchSize: batchSize,
                reviewer: reviewer,
                locale: locale,
                externalRef: externalRef,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled goal estimate in status created.
    static func newScheduledGoalEstimate(_ code: String, name: String) -> ScheduledGoalEstimate {
        return ScheduledGoalEstimate(
            code: code,
            name: name,
            archived: false,
            region: "",
            dosageMg: 0.0,
            category: "",
            batchSize: 0,
            reviewer: "",
            locale: "",
            externalRef: "",
            visible: false,
            status: ScheduledGoalEstimateStatus.created
        )
    }
}
