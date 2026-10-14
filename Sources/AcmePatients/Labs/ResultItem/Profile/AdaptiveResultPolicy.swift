import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive result policy is in its life cycle.
    enum AdaptiveResultPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a adaptive result policy and its current status.
    final class AdaptiveResultPolicy {
        var code: String
        var label: String
        var batchSize: Int
        var threshold: Double
        var retries: Int
        var diagnosisCode: String
        var title: String
        var currency: String
        var active: Bool
        var segment: String
        var unit: String
        var status: AdaptiveResultPolicyStatus

        init(code: String, label: String, batchSize: Int, threshold: Double, retries: Int, diagnosisCode: String, title: String, currency: String, active: Bool, segment: String, unit: String, status: AdaptiveResultPolicyStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.threshold = threshold
            self.retries = retries
            self.diagnosisCode = diagnosisCode
            self.title = title
            self.currency = currency
            self.active = active
            self.segment = segment
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveResultPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveResultPolicyStatus.rejected || next == AdaptiveResultPolicyStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AdaptiveResultPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive result policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveValue() -> Double {
            return (Double(retries) * threshold * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveResultPolicy {
            return AdaptiveResultPolicy(
                code: code,
                label: label,
                batchSize: batchSize,
                threshold: threshold,
                retries: retries,
                diagnosisCode: diagnosisCode,
                title: title,
                currency: currency,
                active: active,
                segment: segment,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive result policy in status proposed.
    static func newAdaptiveResultPolicy(_ code: String, label: String) -> AdaptiveResultPolicy {
        return AdaptiveResultPolicy(
            code: code,
            label: label,
            batchSize: 0,
            threshold: 0.0,
            retries: 0,
            diagnosisCode: "",
            title: "",
            currency: "",
            active: false,
            segment: "",
            unit: "",
            status: AdaptiveResultPolicyStatus.proposed
        )
    }
}
