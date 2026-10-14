import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up quota is in its life cycle.
    enum FollowUpQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A follow up quota. Its code is unique within a tenant.
    final class FollowUpQuota {
        var code: String
        var label: String
        var contactEmail: String
        var description: String
        var version: Int
        var segment: String
        var channel: String
        var category: String
        var currency: String
        var tags: [String]
        var amount: Double
        var status: FollowUpQuotaStatus

        init(code: String, label: String, contactEmail: String, description: String, version: Int, segment: String, channel: String, category: String, currency: String, tags: [String], amount: Double, status: FollowUpQuotaStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.description = description
            self.version = version
            self.segment = segment
            self.channel = channel
            self.category = category
            self.currency = currency
            self.tags = tags
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == FollowUpQuotaStatus.validated || next == FollowUpQuotaStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: FollowUpQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("follow up quota") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return ((Double(version) - amount) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpQuota {
            return FollowUpQuota(
                code: code,
                label: label,
                contactEmail: contactEmail,
                description: description,
                version: version,
                segment: segment,
                channel: channel,
                category: category,
                currency: currency,
                tags: tags,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a follow up quota in status created.
    static func newFollowUpQuota(_ code: String, label: String) -> FollowUpQuota {
        return FollowUpQuota(
            code: code,
            label: label,
            contactEmail: "",
            description: "",
            version: 0,
            segment: "",
            channel: "",
            category: "",
            currency: "",
            tags: [],
            amount: 0.0,
            status: FollowUpQuotaStatus.created
        )
    }
}
