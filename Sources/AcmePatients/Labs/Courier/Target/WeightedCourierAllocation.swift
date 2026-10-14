import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted courier allocation is in its life cycle.
    enum WeightedCourierAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A weighted courier allocation. Its code is unique within a tenant.
    final class WeightedCourierAllocation {
        var code: String
        var name: String
        var diagnosisCode: String
        var allergy: String
        var updatedAt: Int
        var threshold: Double
        var copay: Double
        var status: WeightedCourierAllocationStatus

        init(code: String, name: String, diagnosisCode: String, allergy: String, updatedAt: Int, threshold: Double, copay: Double, status: WeightedCourierAllocationStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.copay = copay
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

        func canMoveTo(_ next: WeightedCourierAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == WeightedCourierAllocationStatus.cancelled
            case .completed:
                return next == WeightedCourierAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCourierAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted courier allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((copay - threshold) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCourierAllocation {
            return WeightedCourierAllocation(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                allergy: allergy,
                updatedAt: updatedAt,
                threshold: threshold,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted courier allocation in status planned.
    static func newWeightedCourierAllocation(_ code: String, name: String) -> WeightedCourierAllocation {
        return WeightedCourierAllocation(
            code: code,
            name: name,
            diagnosisCode: "",
            allergy: "",
            updatedAt: 0,
            threshold: 0.0,
            copay: 0.0,
            status: WeightedCourierAllocationStatus.planned
        )
    }
}
