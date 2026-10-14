import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual rounding rule is in its life cycle.
    enum ManualRoundingRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a manual rounding rule and its current status.
    final class ManualRoundingRule {
        var code: String
        var title: String
        var attempts: Int
        var diagnosisCode: String
        var ratio: Double
        var ceiling: Double
        var batchSize: Int
        var updatedAt: Int
        var phone: String
        var status: ManualRoundingRuleStatus

        init(code: String, title: String, attempts: Int, diagnosisCode: String, ratio: Double, ceiling: Double, batchSize: Int, updatedAt: Int, phone: String, status: ManualRoundingRuleStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.ratio = ratio
            self.ceiling = ceiling
            self.batchSize = batchSize
            self.updatedAt = updatedAt
            self.phone = phone
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

        func canMoveTo(_ next: ManualRoundingRuleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ManualRoundingRuleStatus.ready || next == ManualRoundingRuleStatus.draining
            case .ready:
                return next == ManualRoundingRuleStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ManualRoundingRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual rounding rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual rounding rule") \(code)"
        }

        func netVolume() -> Double {
            return ((ceiling - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ManualRoundingRule {
            return ManualRoundingRule(
                code: code,
                title: title,
                attempts: attempts,
                diagnosisCode: diagnosisCode,
                ratio: ratio,
                ceiling: ceiling,
                batchSize: batchSize,
                updatedAt: updatedAt,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual rounding rule in status idle.
    static func newManualRoundingRule(_ code: String, title: String) -> ManualRoundingRule {
        return ManualRoundingRule(
            code: code,
            title: title,
            attempts: 0,
            diagnosisCode: "",
            ratio: 0.0,
            ceiling: 0.0,
            batchSize: 0,
            updatedAt: 0,
            phone: "",
            status: ManualRoundingRuleStatus.idle
        )
    }
}
