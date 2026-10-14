import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default claim target is in its life cycle.
    enum DefaultClaimTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default claim target as the claim team keeps it.
    final class DefaultClaimTarget {
        var code: String
        var title: String
        var attributes: [String: String]
        var archived: Bool
        var batchSize: Int
        var summary: String
        var approved: Bool
        var graceDays: Int
        var status: DefaultClaimTargetStatus

        init(code: String, title: String, attributes: [String: String], archived: Bool, batchSize: Int, summary: String, approved: Bool, graceDays: Int, status: DefaultClaimTargetStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.archived = archived
            self.batchSize = batchSize
            self.summary = summary
            self.approved = approved
            self.graceDays = graceDays
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

        func canMoveTo(_ next: DefaultClaimTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultClaimTargetStatus.warming || next == DefaultClaimTargetStatus.ready
            case .warming:
                return next == DefaultClaimTargetStatus.draining || next == DefaultClaimTargetStatus.stopped
            case .ready:
                return next == DefaultClaimTargetStatus.draining || next == DefaultClaimTargetStatus.stopped
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

        func moveTo(_ next: DefaultClaimTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default claim target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default claim target") \(code)"
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

        func netLoad() -> Double {
            return ((Double(batchSize) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultClaimTarget {
            return DefaultClaimTarget(
                code: code,
                title: title,
                attributes: attributes,
                archived: archived,
                batchSize: batchSize,
                summary: summary,
                approved: approved,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default claim target in status idle.
    static func newDefaultClaimTarget(_ code: String, title: String) -> DefaultClaimTarget {
        return DefaultClaimTarget(
            code: code,
            title: title,
            attributes: [:],
            archived: false,
            batchSize: 0,
            summary: "",
            approved: false,
            graceDays: 0,
            status: DefaultClaimTargetStatus.idle
        )
    }
}
