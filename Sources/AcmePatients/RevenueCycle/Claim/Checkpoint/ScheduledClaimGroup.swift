import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled claim group is in its life cycle.
    enum ScheduledClaimGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled claim group as the claim team keeps it.
    final class ScheduledClaimGroup {
        var code: String
        var name: String
        var payer: String
        var contactEmail: String
        var tags: [String]
        var reviewer: String
        var category: String
        var retries: Int
        var segment: String
        var status: ScheduledClaimGroupStatus

        init(code: String, name: String, payer: String, contactEmail: String, tags: [String], reviewer: String, category: String, retries: Int, segment: String, status: ScheduledClaimGroupStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.contactEmail = contactEmail
            self.tags = tags
            self.reviewer = reviewer
            self.category = category
            self.retries = retries
            self.segment = segment
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

        func canMoveTo(_ next: ScheduledClaimGroupStatus) -> Bool {
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
                return next == ScheduledClaimGroupStatus.draining || next == ScheduledClaimGroupStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ScheduledClaimGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledClaimGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled claim group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled claim group") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> ScheduledClaimGroup {
            return ScheduledClaimGroup(
                code: code,
                name: name,
                payer: payer,
                contactEmail: contactEmail,
                tags: tags,
                reviewer: reviewer,
                category: category,
                retries: retries,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a scheduled claim group in status idle.
    static func newScheduledClaimGroup(_ code: String, name: String) -> ScheduledClaimGroup {
        return ScheduledClaimGroup(
            code: code,
            name: name,
            payer: "",
            contactEmail: "",
            tags: [],
            reviewer: "",
            category: "",
            retries: 0,
            segment: "",
            status: ScheduledClaimGroupStatus.idle
        )
    }
}
