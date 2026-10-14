import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled proxy milestone is in its life cycle.
    enum ScheduledProxyMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled proxy milestone. Its code is unique within a tenant.
    final class ScheduledProxyMilestone {
        var code: String
        var label: String
        var ward: String
        var refills: Int
        var notes: String
        var patientRef: String
        var createdAt: Int
        var status: ScheduledProxyMilestoneStatus

        init(code: String, label: String, ward: String, refills: Int, notes: String, patientRef: String, createdAt: Int, status: ScheduledProxyMilestoneStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.refills = refills
            self.notes = notes
            self.patientRef = patientRef
            self.createdAt = createdAt
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

        func canMoveTo(_ next: ScheduledProxyMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledProxyMilestoneStatus.revoked || next == ScheduledProxyMilestoneStatus.expired
            case .granted:
                return next == ScheduledProxyMilestoneStatus.revoked || next == ScheduledProxyMilestoneStatus.expired
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

        func moveTo(_ next: ScheduledProxyMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled proxy milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled proxy milestone") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(createdAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledProxyMilestone {
            return ScheduledProxyMilestone(
                code: code,
                label: label,
                ward: ward,
                refills: refills,
                notes: notes,
                patientRef: patientRef,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled proxy milestone in status requested.
    static func newScheduledProxyMilestone(_ code: String, label: String) -> ScheduledProxyMilestone {
        return ScheduledProxyMilestone(
            code: code,
            label: label,
            ward: "",
            refills: 0,
            notes: "",
            patientRef: "",
            createdAt: 0,
            status: ScheduledProxyMilestoneStatus.requested
        )
    }
}
