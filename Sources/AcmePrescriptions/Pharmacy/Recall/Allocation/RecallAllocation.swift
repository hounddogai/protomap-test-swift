import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall allocation is in its life cycle.
    enum RecallAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A recall allocation as the recall team keeps it.
    final class RecallAllocation {
        var code: String
        var title: String
        var revision: Int
        var durationMinutes: Int
        var active: Bool
        var limit: Int
        var visitMinutes: Int
        var tags: [String]
        var source: String
        var ratio: Double
        var status: RecallAllocationStatus

        init(code: String, title: String, revision: Int, durationMinutes: Int, active: Bool, limit: Int, visitMinutes: Int, tags: [String], source: String, ratio: Double, status: RecallAllocationStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.durationMinutes = durationMinutes
            self.active = active
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.tags = tags
            self.source = source
            self.ratio = ratio
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

        func canMoveTo(_ next: RecallAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: RecallAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return (Double(limit) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RecallAllocation {
            return RecallAllocation(
                code: code,
                title: title,
                revision: revision,
                durationMinutes: durationMinutes,
                active: active,
                limit: limit,
                visitMinutes: visitMinutes,
                tags: tags,
                source: source,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a recall allocation in status open.
    static func newRecallAllocation(_ code: String, title: String) -> RecallAllocation {
        return RecallAllocation(
            code: code,
            title: title,
            revision: 0,
            durationMinutes: 0,
            active: false,
            limit: 0,
            visitMinutes: 0,
            tags: [],
            source: "",
            ratio: 0.0,
            status: RecallAllocationStatus.`open`
        )
    }
}
