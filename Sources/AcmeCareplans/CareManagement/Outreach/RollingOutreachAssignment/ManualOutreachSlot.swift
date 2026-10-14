import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual outreach slot is in its life cycle.
    enum ManualOutreachSlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One manual outreach slot, with what the planners need to act on it.
    final class ManualOutreachSlot {
        var code: String
        var name: String
        var limit: Int
        var archived: Bool
        var externalRef: String
        var score: Double
        var encounterID: String
        var visible: Bool
        var ward: String
        var approved: Bool
        var status: ManualOutreachSlotStatus

        init(code: String, name: String, limit: Int, archived: Bool, externalRef: String, score: Double, encounterID: String, visible: Bool, ward: String, approved: Bool, status: ManualOutreachSlotStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.archived = archived
            self.externalRef = externalRef
            self.score = score
            self.encounterID = encounterID
            self.visible = visible
            self.ward = ward
            self.approved = approved
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

        func canMoveTo(_ next: ManualOutreachSlotStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualOutreachSlotStatus.scheduled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: ManualOutreachSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual outreach slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual outreach slot") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(limit) + score) * 100).rounded() / 100
        }

        func copyValue() -> ManualOutreachSlot {
            return ManualOutreachSlot(
                code: code,
                name: name,
                limit: limit,
                archived: archived,
                externalRef: externalRef,
                score: score,
                encounterID: encounterID,
                visible: visible,
                ward: ward,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual outreach slot in status planned.
    static func newManualOutreachSlot(_ code: String, name: String) -> ManualOutreachSlot {
        return ManualOutreachSlot(
            code: code,
            name: name,
            limit: 0,
            archived: false,
            externalRef: "",
            score: 0.0,
            encounterID: "",
            visible: false,
            ward: "",
            approved: false,
            status: ManualOutreachSlotStatus.planned
        )
    }
}
