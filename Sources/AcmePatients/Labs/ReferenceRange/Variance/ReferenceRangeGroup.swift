import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range group is in its life cycle.
    enum ReferenceRangeGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A reference range group. Its code is unique within a tenant.
    final class ReferenceRangeGroup {
        var code: String
        var label: String
        var name: String
        var title: String
        var active: Bool
        var ceiling: Double
        var reviewer: String
        var limit: Int
        var startsAt: Int
        var status: ReferenceRangeGroupStatus

        init(code: String, label: String, name: String, title: String, active: Bool, ceiling: Double, reviewer: String, limit: Int, startsAt: Int, status: ReferenceRangeGroupStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.title = title
            self.active = active
            self.ceiling = ceiling
            self.reviewer = reviewer
            self.limit = limit
            self.startsAt = startsAt
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

        func canMoveTo(_ next: ReferenceRangeGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferenceRangeGroupStatus.closed
            case .pending:
                return next == ReferenceRangeGroupStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ReferenceRangeGroupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("reference range group") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(startsAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeGroup {
            return ReferenceRangeGroup(
                code: code,
                label: label,
                name: name,
                title: title,
                active: active,
                ceiling: ceiling,
                reviewer: reviewer,
                limit: limit,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a reference range group in status draft.
    static func newReferenceRangeGroup(_ code: String, label: String) -> ReferenceRangeGroup {
        return ReferenceRangeGroup(
            code: code,
            label: label,
            name: "",
            title: "",
            active: false,
            ceiling: 0.0,
            reviewer: "",
            limit: 0,
            startsAt: 0,
            status: ReferenceRangeGroupStatus.draft
        )
    }
}
