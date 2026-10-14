import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled risk score record is in its life cycle.
    enum ScheduledRiskScoreRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled risk score record. Its code is unique within a tenant.
    final class ScheduledRiskScoreRecord {
        var code: String
        var label: String
        var retries: Int
        var region: String
        var visible: Bool
        var updatedAt: Int
        var status: ScheduledRiskScoreRecordStatus

        init(code: String, label: String, retries: Int, region: String, visible: Bool, updatedAt: Int, status: ScheduledRiskScoreRecordStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.region = region
            self.visible = visible
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledRiskScoreRecordStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ScheduledRiskScoreRecordStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ScheduledRiskScoreRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled risk score record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled risk score record") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(retries) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRiskScoreRecord {
            return ScheduledRiskScoreRecord(
                code: code,
                label: label,
                retries: retries,
                region: region,
                visible: visible,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled risk score record in status open.
    static func newScheduledRiskScoreRecord(_ code: String, label: String) -> ScheduledRiskScoreRecord {
        return ScheduledRiskScoreRecord(
            code: code,
            label: label,
            retries: 0,
            region: "",
            visible: false,
            updatedAt: 0,
            status: ScheduledRiskScoreRecordStatus.`open`
        )
    }
}
