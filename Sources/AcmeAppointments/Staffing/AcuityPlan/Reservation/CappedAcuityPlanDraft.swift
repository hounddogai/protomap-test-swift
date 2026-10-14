import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped acuity plan draft is in its life cycle.
    enum CappedAcuityPlanDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a capped acuity plan draft and its current status.
    final class CappedAcuityPlanDraft {
        var code: String
        var name: String
        var ownerID: String
        var channel: String
        var refills: Int
        var createdAt: Int
        var ceiling: Double
        var durationMinutes: Int
        var status: CappedAcuityPlanDraftStatus

        init(code: String, name: String, ownerID: String, channel: String, refills: Int, createdAt: Int, ceiling: Double, durationMinutes: Int, status: CappedAcuityPlanDraftStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.channel = channel
            self.refills = refills
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedAcuityPlanDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedAcuityPlanDraftStatus.approved || next == CappedAcuityPlanDraftStatus.withdrawn
            case .approved:
                return next == CappedAcuityPlanDraftStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CappedAcuityPlanDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped acuity plan draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("capped acuity plan draft") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(refills) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CappedAcuityPlanDraft {
            return CappedAcuityPlanDraft(
                code: code,
                name: name,
                ownerID: ownerID,
                channel: channel,
                refills: refills,
                createdAt: createdAt,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped acuity plan draft in status proposed.
    static func newCappedAcuityPlanDraft(_ code: String, name: String) -> CappedAcuityPlanDraft {
        return CappedAcuityPlanDraft(
            code: code,
            name: name,
            ownerID: "",
            channel: "",
            refills: 0,
            createdAt: 0,
            ceiling: 0.0,
            durationMinutes: 0,
            status: CappedAcuityPlanDraftStatus.proposed
        )
    }
}
