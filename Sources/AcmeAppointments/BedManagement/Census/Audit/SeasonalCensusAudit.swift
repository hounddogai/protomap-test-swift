import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal census audit is in its life cycle.
    enum SeasonalCensusAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal census audit. Its code is unique within a tenant.
    final class SeasonalCensusAudit {
        var code: String
        var label: String
        var margin: Double
        var visitMinutes: Int
        var ownerID: String
        var status: SeasonalCensusAuditStatus

        init(code: String, label: String, margin: Double, visitMinutes: Int, ownerID: String, status: SeasonalCensusAuditStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.visitMinutes = visitMinutes
            self.ownerID = ownerID
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

        func canMoveTo(_ next: SeasonalCensusAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalCensusAuditStatus.published
            case .validated:
                return next == SeasonalCensusAuditStatus.published || next == SeasonalCensusAuditStatus.retired
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

        func moveTo(_ next: SeasonalCensusAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal census audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedLoad() -> Double {
            return (Double(visitMinutes) * margin * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCensusAudit {
            return SeasonalCensusAudit(
                code: code,
                label: label,
                margin: margin,
                visitMinutes: visitMinutes,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal census audit in status created.
    static func newSeasonalCensusAudit(_ code: String, label: String) -> SeasonalCensusAudit {
        return SeasonalCensusAudit(
            code: code,
            label: label,
            margin: 0.0,
            visitMinutes: 0,
            ownerID: "",
            status: SeasonalCensusAuditStatus.created
        )
    }
}
