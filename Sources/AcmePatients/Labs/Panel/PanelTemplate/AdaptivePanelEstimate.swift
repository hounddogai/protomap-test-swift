import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive panel estimate is in its life cycle.
    enum AdaptivePanelEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive panel estimate, with what the planners need to act on it.
    final class AdaptivePanelEstimate {
        var code: String
        var label: String
        var capacity: Int
        var specialty: String
        var priority: Int
        var diagnosisCode: String
        var ceiling: Double
        var startsAt: Int
        var budget: Double
        var bed: String
        var status: AdaptivePanelEstimateStatus

        init(code: String, label: String, capacity: Int, specialty: String, priority: Int, diagnosisCode: String, ceiling: Double, startsAt: Int, budget: Double, bed: String, status: AdaptivePanelEstimateStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.specialty = specialty
            self.priority = priority
            self.diagnosisCode = diagnosisCode
            self.ceiling = ceiling
            self.startsAt = startsAt
            self.budget = budget
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptivePanelEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AdaptivePanelEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptivePanelEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive panel estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return (Double(startsAt) * budget * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePanelEstimate {
            return AdaptivePanelEstimate(
                code: code,
                label: label,
                capacity: capacity,
                specialty: specialty,
                priority: priority,
                diagnosisCode: diagnosisCode,
                ceiling: ceiling,
                startsAt: startsAt,
                budget: budget,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive panel estimate in status requested.
    static func newAdaptivePanelEstimate(_ code: String, label: String) -> AdaptivePanelEstimate {
        return AdaptivePanelEstimate(
            code: code,
            label: label,
            capacity: 0,
            specialty: "",
            priority: 0,
            diagnosisCode: "",
            ceiling: 0.0,
            startsAt: 0,
            budget: 0.0,
            bed: "",
            status: AdaptivePanelEstimateStatus.requested
        )
    }
}
