import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual risk score audit is in its life cycle.
    enum ManualRiskScoreAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual risk score audit. Its code is unique within a tenant.
    final class ManualRiskScoreAudit {
        var code: String
        var title: String
        var active: Bool
        var limit: Int
        var timezone: String
        var margin: Double
        var encounterID: String
        var refills: Int
        var status: ManualRiskScoreAuditStatus

        init(code: String, title: String, active: Bool, limit: Int, timezone: String, margin: Double, encounterID: String, refills: Int, status: ManualRiskScoreAuditStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.limit = limit
            self.timezone = timezone
            self.margin = margin
            self.encounterID = encounterID
            self.refills = refills
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

        func canMoveTo(_ next: ManualRiskScoreAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualRiskScoreAuditStatus.published
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: ManualRiskScoreAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual risk score audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual risk score audit") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(limit) * margin * 100).rounded() / 100
        }

        func copyValue() -> ManualRiskScoreAudit {
            return ManualRiskScoreAudit(
                code: code,
                title: title,
                active: active,
                limit: limit,
                timezone: timezone,
                margin: margin,
                encounterID: encounterID,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual risk score audit in status created.
    static func newManualRiskScoreAudit(_ code: String, title: String) -> ManualRiskScoreAudit {
        return ManualRiskScoreAudit(
            code: code,
            title: title,
            active: false,
            limit: 0,
            timezone: "",
            margin: 0.0,
            encounterID: "",
            refills: 0,
            status: ManualRiskScoreAuditStatus.created
        )
    }
}
