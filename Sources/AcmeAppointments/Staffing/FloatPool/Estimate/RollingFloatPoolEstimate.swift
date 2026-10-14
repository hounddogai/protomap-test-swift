import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling float pool estimate is in its life cycle.
    enum RollingFloatPoolEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling float pool estimate as the float pool team keeps it.
    final class RollingFloatPoolEstimate {
        var code: String
        var name: String
        var segment: String
        var tags: [String]
        var country: String
        var allergy: String
        var description: String
        var visible: Bool
        var startsAt: Int
        var active: Bool
        var weight: Double
        var status: RollingFloatPoolEstimateStatus

        init(code: String, name: String, segment: String, tags: [String], country: String, allergy: String, description: String, visible: Bool, startsAt: Int, active: Bool, weight: Double, status: RollingFloatPoolEstimateStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.tags = tags
            self.country = country
            self.allergy = allergy
            self.description = description
            self.visible = visible
            self.startsAt = startsAt
            self.active = active
            self.weight = weight
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

        func canMoveTo(_ next: RollingFloatPoolEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingFloatPoolEstimateStatus.archived
            case .inReview:
                return next == RollingFloatPoolEstimateStatus.resolved || next == RollingFloatPoolEstimateStatus.reopened
            case .resolved:
                return next == RollingFloatPoolEstimateStatus.reopened
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

        func moveTo(_ next: RollingFloatPoolEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling float pool estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return (weight * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> RollingFloatPoolEstimate {
            return RollingFloatPoolEstimate(
                code: code,
                name: name,
                segment: segment,
                tags: tags,
                country: country,
                allergy: allergy,
                description: description,
                visible: visible,
                startsAt: startsAt,
                active: active,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling float pool estimate in status open.
    static func newRollingFloatPoolEstimate(_ code: String, name: String) -> RollingFloatPoolEstimate {
        return RollingFloatPoolEstimate(
            code: code,
            name: name,
            segment: "",
            tags: [],
            country: "",
            allergy: "",
            description: "",
            visible: false,
            startsAt: 0,
            active: false,
            weight: 0.0,
            status: RollingFloatPoolEstimateStatus.`open`
        )
    }
}
