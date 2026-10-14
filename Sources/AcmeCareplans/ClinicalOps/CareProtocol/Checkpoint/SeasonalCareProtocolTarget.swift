import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal care protocol target is in its life cycle.
    enum SeasonalCareProtocolTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a seasonal care protocol target and its current status.
    final class SeasonalCareProtocolTarget {
        var code: String
        var title: String
        var version: Int
        var reviewer: String
        var endsAt: Int
        var active: Bool
        var weight: Double
        var region: String
        var cost: Double
        var status: SeasonalCareProtocolTargetStatus

        init(code: String, title: String, version: Int, reviewer: String, endsAt: Int, active: Bool, weight: Double, region: String, cost: Double, status: SeasonalCareProtocolTargetStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.active = active
            self.weight = weight
            self.region = region
            self.cost = cost
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

        func canMoveTo(_ next: SeasonalCareProtocolTargetStatus) -> Bool {
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
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: SeasonalCareProtocolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care protocol target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveVolume() -> Double {
            return ((Double(endsAt) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCareProtocolTarget {
            return SeasonalCareProtocolTarget(
                code: code,
                title: title,
                version: version,
                reviewer: reviewer,
                endsAt: endsAt,
                active: active,
                weight: weight,
                region: region,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a seasonal care protocol target in status open.
    static func newSeasonalCareProtocolTarget(_ code: String, title: String) -> SeasonalCareProtocolTarget {
        return SeasonalCareProtocolTarget(
            code: code,
            title: title,
            version: 0,
            reviewer: "",
            endsAt: 0,
            active: false,
            weight: 0.0,
            region: "",
            cost: 0.0,
            status: SeasonalCareProtocolTargetStatus.`open`
        )
    }
}
