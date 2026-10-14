import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending courier milestone is in its life cycle.
    enum PendingCourierMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a pending courier milestone and its current status.
    final class PendingCourierMilestone {
        var code: String
        var title: String
        var durationMinutes: Int
        var refills: Int
        var region: String
        var encounterID: String
        var procedureCode: String
        var quantity: Int
        var approved: Bool
        var payer: String
        var category: String
        var status: PendingCourierMilestoneStatus

        init(code: String, title: String, durationMinutes: Int, refills: Int, region: String, encounterID: String, procedureCode: String, quantity: Int, approved: Bool, payer: String, category: String, status: PendingCourierMilestoneStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.refills = refills
            self.region = region
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.approved = approved
            self.payer = payer
            self.category = category
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

        func canMoveTo(_ next: PendingCourierMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == PendingCourierMilestoneStatus.retired
            case .validated:
                return next == PendingCourierMilestoneStatus.published || next == PendingCourierMilestoneStatus.retired
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

        func moveTo(_ next: PendingCourierMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending courier milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((Double(quantity) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCourierMilestone {
            return PendingCourierMilestone(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                refills: refills,
                region: region,
                encounterID: encounterID,
                procedureCode: procedureCode,
                quantity: quantity,
                approved: approved,
                payer: payer,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending courier milestone in status created.
    static func newPendingCourierMilestone(_ code: String, title: String) -> PendingCourierMilestone {
        return PendingCourierMilestone(
            code: code,
            title: title,
            durationMinutes: 0,
            refills: 0,
            region: "",
            encounterID: "",
            procedureCode: "",
            quantity: 0,
            approved: false,
            payer: "",
            category: "",
            status: PendingCourierMilestoneStatus.created
        )
    }
}
