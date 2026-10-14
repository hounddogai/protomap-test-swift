import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending follow up adjustment is in its life cycle.
    enum PendingFollowUpAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a pending follow up adjustment and its current status.
    final class PendingFollowUpAdjustment {
        var code: String
        var name: String
        var facility: String
        var floorValue: Double
        var patientRef: String
        var timezone: String
        var graceDays: Int
        var revision: Int
        var reviewer: String
        var procedureCode: String
        var region: String
        var status: PendingFollowUpAdjustmentStatus

        init(code: String, name: String, facility: String, floorValue: Double, patientRef: String, timezone: String, graceDays: Int, revision: Int, reviewer: String, procedureCode: String, region: String, status: PendingFollowUpAdjustmentStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.floorValue = floorValue
            self.patientRef = patientRef
            self.timezone = timezone
            self.graceDays = graceDays
            self.revision = revision
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.region = region
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

        func canMoveTo(_ next: PendingFollowUpAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingFollowUpAdjustmentStatus.active || next == PendingFollowUpAdjustmentStatus.suspended
            case .pending:
                return next == PendingFollowUpAdjustmentStatus.active
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: PendingFollowUpAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending follow up adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(graceDays) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PendingFollowUpAdjustment {
            return PendingFollowUpAdjustment(
                code: code,
                name: name,
                facility: facility,
                floorValue: floorValue,
                patientRef: patientRef,
                timezone: timezone,
                graceDays: graceDays,
                revision: revision,
                reviewer: reviewer,
                procedureCode: procedureCode,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending follow up adjustment in status draft.
    static func newPendingFollowUpAdjustment(_ code: String, name: String) -> PendingFollowUpAdjustment {
        return PendingFollowUpAdjustment(
            code: code,
            name: name,
            facility: "",
            floorValue: 0.0,
            patientRef: "",
            timezone: "",
            graceDays: 0,
            revision: 0,
            reviewer: "",
            procedureCode: "",
            region: "",
            status: PendingFollowUpAdjustmentStatus.draft
        )
    }
}
