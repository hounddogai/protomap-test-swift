import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual outreach audit is in its life cycle.
    enum ManualOutreachAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual outreach audit. Its code is unique within a tenant.
    final class ManualOutreachAudit {
        var code: String
        var label: String
        var endsAt: Int
        var ceiling: Double
        var durationMinutes: Int
        var encounterID: String
        var status: ManualOutreachAuditStatus

        init(code: String, label: String, endsAt: Int, ceiling: Double, durationMinutes: Int, encounterID: String, status: ManualOutreachAuditStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ManualOutreachAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualOutreachAuditStatus.published || next == ManualOutreachAuditStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualOutreachAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual outreach audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("manual outreach audit") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(endsAt) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ManualOutreachAudit {
            return ManualOutreachAudit(
                code: code,
                label: label,
                endsAt: endsAt,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual outreach audit in status created.
    static func newManualOutreachAudit(_ code: String, label: String) -> ManualOutreachAudit {
        return ManualOutreachAudit(
            code: code,
            label: label,
            endsAt: 0,
            ceiling: 0.0,
            durationMinutes: 0,
            encounterID: "",
            status: ManualOutreachAuditStatus.created
        )
    }
}
