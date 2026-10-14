import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy priority policy is in its life cycle.
    enum LegacyPriorityPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One legacy priority policy, with what the planners need to act on it.
    final class LegacyPriorityPolicy {
        var code: String
        var title: String
        var graceDays: Int
        var retries: Int
        var dosageMg: Double
        var allergy: String
        var batchSize: Int
        var source: String
        var description: String
        var acuity: Int
        var currency: String
        var status: LegacyPriorityPolicyStatus

        init(code: String, title: String, graceDays: Int, retries: Int, dosageMg: Double, allergy: String, batchSize: Int, source: String, description: String, acuity: Int, currency: String, status: LegacyPriorityPolicyStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.retries = retries
            self.dosageMg = dosageMg
            self.allergy = allergy
            self.batchSize = batchSize
            self.source = source
            self.description = description
            self.acuity = acuity
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyPriorityPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyPriorityPolicyStatus.inReview || next == LegacyPriorityPolicyStatus.resolved
            case .inReview:
                return next == LegacyPriorityPolicyStatus.reopened || next == LegacyPriorityPolicyStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LegacyPriorityPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy priority policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return ((dosageMg - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyPriorityPolicy {
            return LegacyPriorityPolicy(
                code: code,
                title: title,
                graceDays: graceDays,
                retries: retries,
                dosageMg: dosageMg,
                allergy: allergy,
                batchSize: batchSize,
                source: source,
                description: description,
                acuity: acuity,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy priority policy in status open.
    static func newLegacyPriorityPolicy(_ code: String, title: String) -> LegacyPriorityPolicy {
        return LegacyPriorityPolicy(
            code: code,
            title: title,
            graceDays: 0,
            retries: 0,
            dosageMg: 0.0,
            allergy: "",
            batchSize: 0,
            source: "",
            description: "",
            acuity: 0,
            currency: "",
            status: LegacyPriorityPolicyStatus.`open`
        )
    }
}
