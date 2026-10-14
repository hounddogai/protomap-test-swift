import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy follow up adjustment is in its life cycle.
    enum LegacyFollowUpAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One legacy follow up adjustment, with what the planners need to act on it.
    final class LegacyFollowUpAdjustment {
        var code: String
        var name: String
        var encounterID: String
        var windowDays: Int
        var sequence: Int
        var status: LegacyFollowUpAdjustmentStatus

        init(code: String, name: String, encounterID: String, windowDays: Int, sequence: Int, status: LegacyFollowUpAdjustmentStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.windowDays = windowDays
            self.sequence = sequence
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

        func canMoveTo(_ next: LegacyFollowUpAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == LegacyFollowUpAdjustmentStatus.validated || next == LegacyFollowUpAdjustmentStatus.published
            case .validated:
                return next == LegacyFollowUpAdjustmentStatus.published || next == LegacyFollowUpAdjustmentStatus.retired
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

        func moveTo(_ next: LegacyFollowUpAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy follow up adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy follow up adjustment") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(sequence) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> LegacyFollowUpAdjustment {
            return LegacyFollowUpAdjustment(
                code: code,
                name: name,
                encounterID: encounterID,
                windowDays: windowDays,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy follow up adjustment in status created.
    static func newLegacyFollowUpAdjustment(_ code: String, name: String) -> LegacyFollowUpAdjustment {
        return LegacyFollowUpAdjustment(
            code: code,
            name: name,
            encounterID: "",
            windowDays: 0,
            sequence: 0,
            status: LegacyFollowUpAdjustmentStatus.created
        )
    }
}
