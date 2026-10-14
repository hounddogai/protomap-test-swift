import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility variance is in its life cycle.
    enum EligibilityVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One eligibility variance, with what the planners need to act on it.
    final class EligibilityVariance {
        var code: String
        var label: String
        var durationMinutes: Int
        var quantity: Int
        var discount: Double
        var summary: String
        var status: EligibilityVarianceStatus

        init(code: String, label: String, durationMinutes: Int, quantity: Int, discount: Double, summary: String, status: EligibilityVarianceStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.discount = discount
            self.summary = summary
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

        func canMoveTo(_ next: EligibilityVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: EligibilityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((Double(durationMinutes) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityVariance {
            return EligibilityVariance(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                quantity: quantity,
                discount: discount,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility variance in status new.
    static func newEligibilityVariance(_ code: String, label: String) -> EligibilityVariance {
        return EligibilityVariance(
            code: code,
            label: label,
            durationMinutes: 0,
            quantity: 0,
            discount: 0.0,
            summary: "",
            status: EligibilityVarianceStatus.new
        )
    }
}
