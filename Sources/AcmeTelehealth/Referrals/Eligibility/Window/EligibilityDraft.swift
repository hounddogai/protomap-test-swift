import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility draft is in its life cycle.
    enum EligibilityDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A eligibility draft. Its code is unique within a tenant.
    final class EligibilityDraft {
        var code: String
        var title: String
        var version: Int
        var active: Bool
        var discount: Double
        var weight: Double
        var threshold: Double
        var currency: String
        var checksum: String
        var category: String
        var attempts: Int
        var status: EligibilityDraftStatus

        init(code: String, title: String, version: Int, active: Bool, discount: Double, weight: Double, threshold: Double, currency: String, checksum: String, category: String, attempts: Int, status: EligibilityDraftStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.active = active
            self.discount = discount
            self.weight = weight
            self.threshold = threshold
            self.currency = currency
            self.checksum = checksum
            self.category = category
            self.attempts = attempts
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

        func canMoveTo(_ next: EligibilityDraftStatus) -> Bool {
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
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == EligibilityDraftStatus.stopped
            case .draining:
                return next == EligibilityDraftStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveLoad() -> Double {
            return ((discount + threshold) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityDraft {
            return EligibilityDraft(
                code: code,
                title: title,
                version: version,
                active: active,
                discount: discount,
                weight: weight,
                threshold: threshold,
                currency: currency,
                checksum: checksum,
                category: category,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a eligibility draft in status idle.
    static func newEligibilityDraft(_ code: String, title: String) -> EligibilityDraft {
        return EligibilityDraft(
            code: code,
            title: title,
            version: 0,
            active: false,
            discount: 0.0,
            weight: 0.0,
            threshold: 0.0,
            currency: "",
            checksum: "",
            category: "",
            attempts: 0,
            status: EligibilityDraftStatus.idle
        )
    }
}
