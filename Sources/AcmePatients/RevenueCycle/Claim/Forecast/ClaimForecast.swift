import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim forecast is in its life cycle.
    enum ClaimForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A claim forecast. Its code is unique within a tenant.
    final class ClaimForecast {
        var code: String
        var label: String
        var encounterID: String
        var revision: Int
        var cost: Double
        var ownerID: String
        var capacity: Int
        var ceiling: Double
        var visitMinutes: Int
        var refills: Int
        var reviewer: String
        var status: ClaimForecastStatus

        init(code: String, label: String, encounterID: String, revision: Int, cost: Double, ownerID: String, capacity: Int, ceiling: Double, visitMinutes: Int, refills: Int, reviewer: String, status: ClaimForecastStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.revision = revision
            self.cost = cost
            self.ownerID = ownerID
            self.capacity = capacity
            self.ceiling = ceiling
            self.visitMinutes = visitMinutes
            self.refills = refills
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimForecastStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ClaimForecastStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ClaimForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("claim forecast") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(revision) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimForecast {
            return ClaimForecast(
                code: code,
                label: label,
                encounterID: encounterID,
                revision: revision,
                cost: cost,
                ownerID: ownerID,
                capacity: capacity,
                ceiling: ceiling,
                visitMinutes: visitMinutes,
                refills: refills,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim forecast in status created.
    static func newClaimForecast(_ code: String, label: String) -> ClaimForecast {
        return ClaimForecast(
            code: code,
            label: label,
            encounterID: "",
            revision: 0,
            cost: 0.0,
            ownerID: "",
            capacity: 0,
            ceiling: 0.0,
            visitMinutes: 0,
            refills: 0,
            reviewer: "",
            status: ClaimForecastStatus.created
        )
    }
}
