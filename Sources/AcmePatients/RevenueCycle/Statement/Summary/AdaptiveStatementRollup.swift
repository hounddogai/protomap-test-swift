import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive statement rollup is in its life cycle.
    enum AdaptiveStatementRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A adaptive statement rollup as the statement team keeps it.
    final class AdaptiveStatementRollup {
        var code: String
        var title: String
        var refills: Int
        var archived: Bool
        var windowDays: Int
        var startsAt: Int
        var attributes: [String: String]
        var allergy: String
        var reviewer: String
        var status: AdaptiveStatementRollupStatus

        init(code: String, title: String, refills: Int, archived: Bool, windowDays: Int, startsAt: Int, attributes: [String: String], allergy: String, reviewer: String, status: AdaptiveStatementRollupStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.archived = archived
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.attributes = attributes
            self.allergy = allergy
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

        func canMoveTo(_ next: AdaptiveStatementRollupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AdaptiveStatementRollupStatus.completed || next == AdaptiveStatementRollupStatus.cancelled
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

        func moveTo(_ next: AdaptiveStatementRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive statement rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func netExposure() -> Double {
            return (Double(refills) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStatementRollup {
            return AdaptiveStatementRollup(
                code: code,
                title: title,
                refills: refills,
                archived: archived,
                windowDays: windowDays,
                startsAt: startsAt,
                attributes: attributes,
                allergy: allergy,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive statement rollup in status planned.
    static func newAdaptiveStatementRollup(_ code: String, title: String) -> AdaptiveStatementRollup {
        return AdaptiveStatementRollup(
            code: code,
            title: title,
            refills: 0,
            archived: false,
            windowDays: 0,
            startsAt: 0,
            attributes: [:],
            allergy: "",
            reviewer: "",
            status: AdaptiveStatementRollupStatus.planned
        )
    }
}
