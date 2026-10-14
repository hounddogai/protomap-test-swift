import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy census milestone is in its life cycle.
    enum LegacyCensusMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy census milestone and its current status.
    final class LegacyCensusMilestone {
        var code: String
        var name: String
        var locale: String
        var floorValue: Double
        var startsAt: Int
        var endsAt: Int
        var category: String
        var tags: [String]
        var budget: Double
        var reviewer: String
        var status: LegacyCensusMilestoneStatus

        init(code: String, name: String, locale: String, floorValue: Double, startsAt: Int, endsAt: Int, category: String, tags: [String], budget: Double, reviewer: String, status: LegacyCensusMilestoneStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.floorValue = floorValue
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.category = category
            self.tags = tags
            self.budget = budget
            self.reviewer = reviewer
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

        func canMoveTo(_ next: LegacyCensusMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyCensusMilestoneStatus.scheduled || next == LegacyCensusMilestoneStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LegacyCensusMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCensusMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy census milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy census milestone") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (budget * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCensusMilestone {
            return LegacyCensusMilestone(
                code: code,
                name: name,
                locale: locale,
                floorValue: floorValue,
                startsAt: startsAt,
                endsAt: endsAt,
                category: category,
                tags: tags,
                budget: budget,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy census milestone in status planned.
    static func newLegacyCensusMilestone(_ code: String, name: String) -> LegacyCensusMilestone {
        return LegacyCensusMilestone(
            code: code,
            name: name,
            locale: "",
            floorValue: 0.0,
            startsAt: 0,
            endsAt: 0,
            category: "",
            tags: [],
            budget: 0.0,
            reviewer: "",
            status: LegacyCensusMilestoneStatus.planned
        )
    }
}
