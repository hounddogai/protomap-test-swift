import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive discharge plan tier is in its life cycle.
    enum AdaptiveDischargePlanTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a adaptive discharge plan tier and its current status.
    final class AdaptiveDischargePlanTier {
        var code: String
        var name: String
        var archived: Bool
        var margin: Double
        var version: Int
        var tags: [String]
        var attempts: Int
        var allergy: String
        var status: AdaptiveDischargePlanTierStatus

        init(code: String, name: String, archived: Bool, margin: Double, version: Int, tags: [String], attempts: Int, allergy: String, status: AdaptiveDischargePlanTierStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.margin = margin
            self.version = version
            self.tags = tags
            self.attempts = attempts
            self.allergy = allergy
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

        func canMoveTo(_ next: AdaptiveDischargePlanTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AdaptiveDischargePlanTierStatus.completed
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

        func moveTo(_ next: AdaptiveDischargePlanTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive discharge plan tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(version) + margin) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDischargePlanTier {
            return AdaptiveDischargePlanTier(
                code: code,
                name: name,
                archived: archived,
                margin: margin,
                version: version,
                tags: tags,
                attempts: attempts,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive discharge plan tier in status planned.
    static func newAdaptiveDischargePlanTier(_ code: String, name: String) -> AdaptiveDischargePlanTier {
        return AdaptiveDischargePlanTier(
            code: code,
            name: name,
            archived: false,
            margin: 0.0,
            version: 0,
            tags: [],
            attempts: 0,
            allergy: "",
            status: AdaptiveDischargePlanTierStatus.planned
        )
    }
}
