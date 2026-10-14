import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted recall notice is in its life cycle.
    enum WeightedRecallNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted recall notice. Its code is unique within a tenant.
    final class WeightedRecallNotice {
        var code: String
        var label: String
        var unit: String
        var encounterID: String
        var ownerID: String
        var acuity: Int
        var allergy: String
        var approved: Bool
        var status: WeightedRecallNoticeStatus

        init(code: String, label: String, unit: String, encounterID: String, ownerID: String, acuity: Int, allergy: String, approved: Bool, status: WeightedRecallNoticeStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.acuity = acuity
            self.allergy = allergy
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRecallNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedRecallNoticeStatus.active
            case .pending:
                return next == WeightedRecallNoticeStatus.suspended || next == WeightedRecallNoticeStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: WeightedRecallNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted recall notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> WeightedRecallNotice {
            return WeightedRecallNotice(
                code: code,
                label: label,
                unit: unit,
                encounterID: encounterID,
                ownerID: ownerID,
                acuity: acuity,
                allergy: allergy,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted recall notice in status draft.
    static func newWeightedRecallNotice(_ code: String, label: String) -> WeightedRecallNotice {
        return WeightedRecallNotice(
            code: code,
            label: label,
            unit: "",
            encounterID: "",
            ownerID: "",
            acuity: 0,
            allergy: "",
            approved: false,
            status: WeightedRecallNoticeStatus.draft
        )
    }
}
