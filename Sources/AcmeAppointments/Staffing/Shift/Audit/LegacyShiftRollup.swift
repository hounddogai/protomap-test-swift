import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy shift rollup is in its life cycle.
    enum LegacyShiftRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy shift rollup as the shift team keeps it.
    final class LegacyShiftRollup {
        var code: String
        var name: String
        var budget: Double
        var encounterID: String
        var region: String
        var approved: Bool
        var active: Bool
        var ratio: Double
        var copay: Double
        var score: Double
        var status: LegacyShiftRollupStatus

        init(code: String, name: String, budget: Double, encounterID: String, region: String, approved: Bool, active: Bool, ratio: Double, copay: Double, score: Double, status: LegacyShiftRollupStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.encounterID = encounterID
            self.region = region
            self.approved = approved
            self.active = active
            self.ratio = ratio
            self.copay = copay
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyShiftRollupStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyShiftRollupStatus.ready
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LegacyShiftRollupStatus.draining || next == LegacyShiftRollupStatus.stopped
            case .draining:
                return next == LegacyShiftRollupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyShiftRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy shift rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy shift rollup") \(code)"
        }

        func weightedExposure() -> Double {
            return ((score + budget) * 100).rounded() / 100
        }

        func copyValue() -> LegacyShiftRollup {
            return LegacyShiftRollup(
                code: code,
                name: name,
                budget: budget,
                encounterID: encounterID,
                region: region,
                approved: approved,
                active: active,
                ratio: ratio,
                copay: copay,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy shift rollup in status idle.
    static func newLegacyShiftRollup(_ code: String, name: String) -> LegacyShiftRollup {
        return LegacyShiftRollup(
            code: code,
            name: name,
            budget: 0.0,
            encounterID: "",
            region: "",
            approved: false,
            active: false,
            ratio: 0.0,
            copay: 0.0,
            score: 0.0,
            status: LegacyShiftRollupStatus.idle
        )
    }
}
