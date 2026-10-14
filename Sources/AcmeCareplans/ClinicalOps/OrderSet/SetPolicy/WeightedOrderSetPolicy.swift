import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted order set policy is in its life cycle.
    enum WeightedOrderSetPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a weighted order set policy and its current status.
    final class WeightedOrderSetPolicy {
        var code: String
        var label: String
        var graceDays: Int
        var ceiling: Double
        var procedureCode: String
        var retries: Int
        var payer: String
        var bed: String
        var priority: Int
        var endsAt: Int
        var attempts: Int
        var status: WeightedOrderSetPolicyStatus

        init(code: String, label: String, graceDays: Int, ceiling: Double, procedureCode: String, retries: Int, payer: String, bed: String, priority: Int, endsAt: Int, attempts: Int, status: WeightedOrderSetPolicyStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.procedureCode = procedureCode
            self.retries = retries
            self.payer = payer
            self.bed = bed
            self.priority = priority
            self.endsAt = endsAt
            self.attempts = attempts
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

        func canMoveTo(_ next: WeightedOrderSetPolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: WeightedOrderSetPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted order set policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedTotal() -> Double {
            return ((Double(retries) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOrderSetPolicy {
            return WeightedOrderSetPolicy(
                code: code,
                label: label,
                graceDays: graceDays,
                ceiling: ceiling,
                procedureCode: procedureCode,
                retries: retries,
                payer: payer,
                bed: bed,
                priority: priority,
                endsAt: endsAt,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted order set policy in status new.
    static func newWeightedOrderSetPolicy(_ code: String, label: String) -> WeightedOrderSetPolicy {
        return WeightedOrderSetPolicy(
            code: code,
            label: label,
            graceDays: 0,
            ceiling: 0.0,
            procedureCode: "",
            retries: 0,
            payer: "",
            bed: "",
            priority: 0,
            endsAt: 0,
            attempts: 0,
            status: WeightedOrderSetPolicyStatus.new
        )
    }
}
