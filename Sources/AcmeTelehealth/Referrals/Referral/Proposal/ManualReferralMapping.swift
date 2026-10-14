import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual referral mapping is in its life cycle.
    enum ManualReferralMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual referral mapping as the referral team keeps it.
    final class ManualReferralMapping {
        var code: String
        var label: String
        var description: String
        var attributes: [String: String]
        var amount: Double
        var windowDays: Int
        var ceiling: Double
        var score: Double
        var currency: String
        var version: Int
        var contactEmail: String
        var status: ManualReferralMappingStatus

        init(code: String, label: String, description: String, attributes: [String: String], amount: Double, windowDays: Int, ceiling: Double, score: Double, currency: String, version: Int, contactEmail: String, status: ManualReferralMappingStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.attributes = attributes
            self.amount = amount
            self.windowDays = windowDays
            self.ceiling = ceiling
            self.score = score
            self.currency = currency
            self.version = version
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualReferralMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ManualReferralMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual referral mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("manual referral mapping") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((ceiling + score) * 100).rounded() / 100
        }

        func copyValue() -> ManualReferralMapping {
            return ManualReferralMapping(
                code: code,
                label: label,
                description: description,
                attributes: attributes,
                amount: amount,
                windowDays: windowDays,
                ceiling: ceiling,
                score: score,
                currency: currency,
                version: version,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual referral mapping in status planned.
    static func newManualReferralMapping(_ code: String, label: String) -> ManualReferralMapping {
        return ManualReferralMapping(
            code: code,
            label: label,
            description: "",
            attributes: [:],
            amount: 0.0,
            windowDays: 0,
            ceiling: 0.0,
            score: 0.0,
            currency: "",
            version: 0,
            contactEmail: "",
            status: ManualReferralMappingStatus.planned
        )
    }
}
