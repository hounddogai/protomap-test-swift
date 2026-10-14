import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted risk score policy is in its life cycle.
    enum WeightedRiskScorePolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One weighted risk score policy, with what the planners need to act on it.
    final class WeightedRiskScorePolicy {
        var code: String
        var label: String
        var graceDays: Int
        var clinicianID: String
        var expiresAt: Int
        var diagnosisCode: String
        var threshold: Double
        var amount: Double
        var notes: String
        var status: WeightedRiskScorePolicyStatus

        init(code: String, label: String, graceDays: Int, clinicianID: String, expiresAt: Int, diagnosisCode: String, threshold: Double, amount: Double, notes: String, status: WeightedRiskScorePolicyStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.clinicianID = clinicianID
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
            self.threshold = threshold
            self.amount = amount
            self.notes = notes
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

        func canMoveTo(_ next: WeightedRiskScorePolicyStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == WeightedRiskScorePolicyStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedRiskScorePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted risk score policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("weighted risk score policy") \(code)"
        }

        func effectiveExposure() -> Double {
            return (threshold * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRiskScorePolicy {
            return WeightedRiskScorePolicy(
                code: code,
                label: label,
                graceDays: graceDays,
                clinicianID: clinicianID,
                expiresAt: expiresAt,
                diagnosisCode: diagnosisCode,
                threshold: threshold,
                amount: amount,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted risk score policy in status idle.
    static func newWeightedRiskScorePolicy(_ code: String, label: String) -> WeightedRiskScorePolicy {
        return WeightedRiskScorePolicy(
            code: code,
            label: label,
            graceDays: 0,
            clinicianID: "",
            expiresAt: 0,
            diagnosisCode: "",
            threshold: 0.0,
            amount: 0.0,
            notes: "",
            status: WeightedRiskScorePolicyStatus.idle
        )
    }
}
