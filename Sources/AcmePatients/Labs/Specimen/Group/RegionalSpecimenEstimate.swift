import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional specimen estimate is in its life cycle.
    enum RegionalSpecimenEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One regional specimen estimate, with what the planners need to act on it.
    final class RegionalSpecimenEstimate {
        var code: String
        var label: String
        var diagnosisCode: String
        var attempts: Int
        var visible: Bool
        var budget: Double
        var status: RegionalSpecimenEstimateStatus

        init(code: String, label: String, diagnosisCode: String, attempts: Int, visible: Bool, budget: Double, status: RegionalSpecimenEstimateStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.attempts = attempts
            self.visible = visible
            self.budget = budget
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

        func canMoveTo(_ next: RegionalSpecimenEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalSpecimenEstimateStatus.running || next == RegionalSpecimenEstimateStatus.done
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RegionalSpecimenEstimateStatus.done
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

        func moveTo(_ next: RegionalSpecimenEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional specimen estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedVolume() -> Double {
            return ((Double(attempts) - budget) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSpecimenEstimate {
            return RegionalSpecimenEstimate(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                attempts: attempts,
                visible: visible,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional specimen estimate in status new.
    static func newRegionalSpecimenEstimate(_ code: String, label: String) -> RegionalSpecimenEstimate {
        return RegionalSpecimenEstimate(
            code: code,
            label: label,
            diagnosisCode: "",
            attempts: 0,
            visible: false,
            budget: 0.0,
            status: RegionalSpecimenEstimateStatus.new
        )
    }
}
