import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered priority schedule is in its life cycle.
    enum TieredPriorityScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered priority schedule and its current status.
    final class TieredPrioritySchedule {
        var code: String
        var label: String
        var weight: Double
        var tags: [String]
        var revision: Int
        var country: String
        var threshold: Double
        var approved: Bool
        var summary: String
        var status: TieredPriorityScheduleStatus

        init(code: String, label: String, weight: Double, tags: [String], revision: Int, country: String, threshold: Double, approved: Bool, summary: String, status: TieredPriorityScheduleStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.tags = tags
            self.revision = revision
            self.country = country
            self.threshold = threshold
            self.approved = approved
            self.summary = summary
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

        func canMoveTo(_ next: TieredPriorityScheduleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TieredPriorityScheduleStatus.active
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TieredPriorityScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered priority schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((Double(revision) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> TieredPrioritySchedule {
            return TieredPrioritySchedule(
                code: code,
                label: label,
                weight: weight,
                tags: tags,
                revision: revision,
                country: country,
                threshold: threshold,
                approved: approved,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered priority schedule in status draft.
    static func newTieredPrioritySchedule(_ code: String, label: String) -> TieredPrioritySchedule {
        return TieredPrioritySchedule(
            code: code,
            label: label,
            weight: 0.0,
            tags: [],
            revision: 0,
            country: "",
            threshold: 0.0,
            approved: false,
            summary: "",
            status: TieredPriorityScheduleStatus.draft
        )
    }
}
