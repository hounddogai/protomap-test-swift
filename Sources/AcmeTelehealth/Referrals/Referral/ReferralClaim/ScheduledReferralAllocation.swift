import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled referral allocation is in its life cycle.
    enum ScheduledReferralAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled referral allocation. Its code is unique within a tenant.
    final class ScheduledReferralAllocation {
        var code: String
        var label: String
        var durationMinutes: Int
        var capacity: Int
        var tags: [String]
        var revision: Int
        var phone: String
        var attributes: [String: String]
        var status: ScheduledReferralAllocationStatus

        init(code: String, label: String, durationMinutes: Int, capacity: Int, tags: [String], revision: Int, phone: String, attributes: [String: String], status: ScheduledReferralAllocationStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.capacity = capacity
            self.tags = tags
            self.revision = revision
            self.phone = phone
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledReferralAllocationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ScheduledReferralAllocationStatus.suspended || next == ScheduledReferralAllocationStatus.closed
            case .suspended:
                return next == ScheduledReferralAllocationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledReferralAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled referral allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("scheduled referral allocation") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func weightedVolume() -> Double {
            return (Double(capacity) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledReferralAllocation {
            return ScheduledReferralAllocation(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                capacity: capacity,
                tags: tags,
                revision: revision,
                phone: phone,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled referral allocation in status draft.
    static func newScheduledReferralAllocation(_ code: String, label: String) -> ScheduledReferralAllocation {
        return ScheduledReferralAllocation(
            code: code,
            label: label,
            durationMinutes: 0,
            capacity: 0,
            tags: [],
            revision: 0,
            phone: "",
            attributes: [:],
            status: ScheduledReferralAllocationStatus.draft
        )
    }
}
