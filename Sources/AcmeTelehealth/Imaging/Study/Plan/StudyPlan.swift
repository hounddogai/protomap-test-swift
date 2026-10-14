import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study plan is in its life cycle.
    enum StudyPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A study plan as the study team keeps it.
    final class StudyPlan {
        var code: String
        var name: String
        var region: String
        var quantity: Int
        var batchSize: Int
        var cost: Double
        var active: Bool
        var unit: String
        var status: StudyPlanStatus

        init(code: String, name: String, region: String, quantity: Int, batchSize: Int, cost: Double, active: Bool, unit: String, status: StudyPlanStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.quantity = quantity
            self.batchSize = batchSize
            self.cost = cost
            self.active = active
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudyPlanStatus) -> Bool {
            switch status {
            case .new:
                return next == StudyPlanStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StudyPlanStatus.done || next == StudyPlanStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: StudyPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveValue() -> Double {
            return ((Double(batchSize) - cost) * 100).rounded() / 100
        }

        func copyValue() -> StudyPlan {
            return StudyPlan(
                code: code,
                name: name,
                region: region,
                quantity: quantity,
                batchSize: batchSize,
                cost: cost,
                active: active,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a study plan in status new.
    static func newStudyPlan(_ code: String, name: String) -> StudyPlan {
        return StudyPlan(
            code: code,
            name: name,
            region: "",
            quantity: 0,
            batchSize: 0,
            cost: 0.0,
            active: false,
            unit: "",
            status: StudyPlanStatus.new
        )
    }
}
