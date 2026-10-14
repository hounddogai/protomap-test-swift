import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling overtime score is in its life cycle.
    enum RollingOvertimeScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling overtime score. Its code is unique within a tenant.
    final class RollingOvertimeScore {
        var code: String
        var label: String
        var region: String
        var title: String
        var active: Bool
        var encounterID: String
        var approved: Bool
        var procedureCode: String
        var amount: Double
        var status: RollingOvertimeScoreStatus

        init(code: String, label: String, region: String, title: String, active: Bool, encounterID: String, approved: Bool, procedureCode: String, amount: Double, status: RollingOvertimeScoreStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.title = title
            self.active = active
            self.encounterID = encounterID
            self.approved = approved
            self.procedureCode = procedureCode
            self.amount = amount
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

        func canMoveTo(_ next: RollingOvertimeScoreStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingOvertimeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling overtime score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RollingOvertimeScore {
            return RollingOvertimeScore(
                code: code,
                label: label,
                region: region,
                title: title,
                active: active,
                encounterID: encounterID,
                approved: approved,
                procedureCode: procedureCode,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling overtime score in status created.
    static func newRollingOvertimeScore(_ code: String, label: String) -> RollingOvertimeScore {
        return RollingOvertimeScore(
            code: code,
            label: label,
            region: "",
            title: "",
            active: false,
            encounterID: "",
            approved: false,
            procedureCode: "",
            amount: 0.0,
            status: RollingOvertimeScoreStatus.created
        )
    }
}
