import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual order set group is in its life cycle.
    enum ManualOrderSetGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a manual order set group and its current status.
    final class ManualOrderSetGroup {
        var code: String
        var name: String
        var cost: Double
        var endsAt: Int
        var summary: String
        var notes: String
        var encounterID: String
        var status: ManualOrderSetGroupStatus

        init(code: String, name: String, cost: Double, endsAt: Int, summary: String, notes: String, encounterID: String, status: ManualOrderSetGroupStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.endsAt = endsAt
            self.summary = summary
            self.notes = notes
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ManualOrderSetGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualOrderSetGroupStatus.inProgress || next == ManualOrderSetGroupStatus.cancelled
            case .scheduled:
                return next == ManualOrderSetGroupStatus.inProgress || next == ManualOrderSetGroupStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ManualOrderSetGroupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualOrderSetGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual order set group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual order set group") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((cost - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualOrderSetGroup {
            return ManualOrderSetGroup(
                code: code,
                name: name,
                cost: cost,
                endsAt: endsAt,
                summary: summary,
                notes: notes,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual order set group in status planned.
    static func newManualOrderSetGroup(_ code: String, name: String) -> ManualOrderSetGroup {
        return ManualOrderSetGroup(
            code: code,
            name: name,
            cost: 0.0,
            endsAt: 0,
            summary: "",
            notes: "",
            encounterID: "",
            status: ManualOrderSetGroupStatus.planned
        )
    }
}
