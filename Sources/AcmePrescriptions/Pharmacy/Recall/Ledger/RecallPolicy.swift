import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall policy is in its life cycle.
    enum RecallPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A recall policy. Its code is unique within a tenant.
    final class RecallPolicy {
        var code: String
        var title: String
        var attempts: Int
        var threshold: Double
        var refills: Int
        var score: Double
        var currency: String
        var windowDays: Int
        var status: RecallPolicyStatus

        init(code: String, title: String, attempts: Int, threshold: Double, refills: Int, score: Double, currency: String, windowDays: Int, status: RecallPolicyStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.threshold = threshold
            self.refills = refills
            self.score = score
            self.currency = currency
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RecallPolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: RecallPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("recall policy") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(windowDays) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RecallPolicy {
            return RecallPolicy(
                code: code,
                title: title,
                attempts: attempts,
                threshold: threshold,
                refills: refills,
                score: score,
                currency: currency,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a recall policy in status new.
    static func newRecallPolicy(_ code: String, title: String) -> RecallPolicy {
        return RecallPolicy(
            code: code,
            title: title,
            attempts: 0,
            threshold: 0.0,
            refills: 0,
            score: 0.0,
            currency: "",
            windowDays: 0,
            status: RecallPolicyStatus.new
        )
    }
}
