import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled modality audit is in its life cycle.
    enum ScheduledModalityAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled modality audit. Its code is unique within a tenant.
    final class ScheduledModalityAudit {
        var code: String
        var title: String
        var batchSize: Int
        var diagnosisCode: String
        var ratio: Double
        var timezone: String
        var status: ScheduledModalityAuditStatus

        init(code: String, title: String, batchSize: Int, diagnosisCode: String, ratio: Double, timezone: String, status: ScheduledModalityAuditStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.diagnosisCode = diagnosisCode
            self.ratio = ratio
            self.timezone = timezone
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

        func canMoveTo(_ next: ScheduledModalityAuditStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledModalityAuditStatus.withdrawn
            case .approved:
                return next == ScheduledModalityAuditStatus.rejected || next == ScheduledModalityAuditStatus.withdrawn
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

        func moveTo(_ next: ScheduledModalityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled modality audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled modality audit") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(batchSize) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledModalityAudit {
            return ScheduledModalityAudit(
                code: code,
                title: title,
                batchSize: batchSize,
                diagnosisCode: diagnosisCode,
                ratio: ratio,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled modality audit in status proposed.
    static func newScheduledModalityAudit(_ code: String, title: String) -> ScheduledModalityAudit {
        return ScheduledModalityAudit(
            code: code,
            title: title,
            batchSize: 0,
            diagnosisCode: "",
            ratio: 0.0,
            timezone: "",
            status: ScheduledModalityAuditStatus.proposed
        )
    }
}
