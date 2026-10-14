import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim plan is in its life cycle.
    enum ClaimPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a claim plan and its current status.
    final class ClaimPlan {
        var code: String
        var title: String
        var label: String
        var floorValue: Double
        var specialty: String
        var diagnosisCode: String
        var sequence: Int
        var allergy: String
        var capacity: Int
        var unit: String
        var category: String
        var status: ClaimPlanStatus

        init(code: String, title: String, label: String, floorValue: Double, specialty: String, diagnosisCode: String, sequence: Int, allergy: String, capacity: Int, unit: String, category: String, status: ClaimPlanStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.floorValue = floorValue
            self.specialty = specialty
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.allergy = allergy
            self.capacity = capacity
            self.unit = unit
            self.category = category
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

        func canMoveTo(_ next: ClaimPlanStatus) -> Bool {
            switch status {
            case .new:
                return next == ClaimPlanStatus.done || next == ClaimPlanStatus.failed
            case .queued:
                return next == ClaimPlanStatus.running || next == ClaimPlanStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ClaimPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return ((Double(capacity) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimPlan {
            return ClaimPlan(
                code: code,
                title: title,
                label: label,
                floorValue: floorValue,
                specialty: specialty,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                allergy: allergy,
                capacity: capacity,
                unit: unit,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a claim plan in status new.
    static func newClaimPlan(_ code: String, title: String) -> ClaimPlan {
        return ClaimPlan(
            code: code,
            title: title,
            label: "",
            floorValue: 0.0,
            specialty: "",
            diagnosisCode: "",
            sequence: 0,
            allergy: "",
            capacity: 0,
            unit: "",
            category: "",
            status: ClaimPlanStatus.new
        )
    }
}
