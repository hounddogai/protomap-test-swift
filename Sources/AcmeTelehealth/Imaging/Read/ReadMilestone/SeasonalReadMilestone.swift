import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal read milestone is in its life cycle.
    enum SeasonalReadMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One seasonal read milestone, with what the planners need to act on it.
    final class SeasonalReadMilestone {
        var code: String
        var name: String
        var country: String
        var unit: String
        var capacity: Int
        var facility: String
        var reviewer: String
        var createdAt: Int
        var score: Double
        var weight: Double
        var discount: Double
        var status: SeasonalReadMilestoneStatus

        init(code: String, name: String, country: String, unit: String, capacity: Int, facility: String, reviewer: String, createdAt: Int, score: Double, weight: Double, discount: Double, status: SeasonalReadMilestoneStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.unit = unit
            self.capacity = capacity
            self.facility = facility
            self.reviewer = reviewer
            self.createdAt = createdAt
            self.score = score
            self.weight = weight
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalReadMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SeasonalReadMilestoneStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: SeasonalReadMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal read milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal read milestone") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(capacity) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalReadMilestone {
            return SeasonalReadMilestone(
                code: code,
                name: name,
                country: country,
                unit: unit,
                capacity: capacity,
                facility: facility,
                reviewer: reviewer,
                createdAt: createdAt,
                score: score,
                weight: weight,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a seasonal read milestone in status requested.
    static func newSeasonalReadMilestone(_ code: String, name: String) -> SeasonalReadMilestone {
        return SeasonalReadMilestone(
            code: code,
            name: name,
            country: "",
            unit: "",
            capacity: 0,
            facility: "",
            reviewer: "",
            createdAt: 0,
            score: 0.0,
            weight: 0.0,
            discount: 0.0,
            status: SeasonalReadMilestoneStatus.requested
        )
    }
}
