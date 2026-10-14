import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive goal baseline is in its life cycle.
    enum AdaptiveGoalBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a adaptive goal baseline and its current status.
    final class AdaptiveGoalBaseline {
        var code: String
        var title: String
        var visible: Bool
        var floorValue: Double
        var revision: Int
        var updatedAt: Int
        var patientRef: String
        var category: String
        var discount: Double
        var ratio: Double
        var approved: Bool
        var status: AdaptiveGoalBaselineStatus

        init(code: String, title: String, visible: Bool, floorValue: Double, revision: Int, updatedAt: Int, patientRef: String, category: String, discount: Double, ratio: Double, approved: Bool, status: AdaptiveGoalBaselineStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.floorValue = floorValue
            self.revision = revision
            self.updatedAt = updatedAt
            self.patientRef = patientRef
            self.category = category
            self.discount = discount
            self.ratio = ratio
            self.approved = approved
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

        func canMoveTo(_ next: AdaptiveGoalBaselineStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AdaptiveGoalBaselineStatus.cancelled
            case .inProgress:
                return next == AdaptiveGoalBaselineStatus.cancelled
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

        func moveTo(_ next: AdaptiveGoalBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive goal baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("adaptive goal baseline") \(code)"
        }

        func netValue() -> Double {
            return ((Double(updatedAt) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveGoalBaseline {
            return AdaptiveGoalBaseline(
                code: code,
                title: title,
                visible: visible,
                floorValue: floorValue,
                revision: revision,
                updatedAt: updatedAt,
                patientRef: patientRef,
                category: category,
                discount: discount,
                ratio: ratio,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive goal baseline in status planned.
    static func newAdaptiveGoalBaseline(_ code: String, title: String) -> AdaptiveGoalBaseline {
        return AdaptiveGoalBaseline(
            code: code,
            title: title,
            visible: false,
            floorValue: 0.0,
            revision: 0,
            updatedAt: 0,
            patientRef: "",
            category: "",
            discount: 0.0,
            ratio: 0.0,
            approved: false,
            status: AdaptiveGoalBaselineStatus.planned
        )
    }
}
