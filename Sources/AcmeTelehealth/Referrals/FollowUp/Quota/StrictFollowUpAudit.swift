import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict follow up audit is in its life cycle.
    enum StrictFollowUpAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict follow up audit. Its code is unique within a tenant.
    final class StrictFollowUpAudit {
        var code: String
        var title: String
        var diagnosisCode: String
        var floorValue: Double
        var name: String
        var reviewer: String
        var cost: Double
        var ward: String
        var locale: String
        var margin: Double
        var maximum: Double
        var status: StrictFollowUpAuditStatus

        init(code: String, title: String, diagnosisCode: String, floorValue: Double, name: String, reviewer: String, cost: Double, ward: String, locale: String, margin: Double, maximum: Double, status: StrictFollowUpAuditStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.floorValue = floorValue
            self.name = name
            self.reviewer = reviewer
            self.cost = cost
            self.ward = ward
            self.locale = locale
            self.margin = margin
            self.maximum = maximum
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

        func canMoveTo(_ next: StrictFollowUpAuditStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StrictFollowUpAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict follow up audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveVolume() -> Double {
            return (floorValue * cost * 100).rounded() / 100
        }

        func copyValue() -> StrictFollowUpAudit {
            return StrictFollowUpAudit(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                floorValue: floorValue,
                name: name,
                reviewer: reviewer,
                cost: cost,
                ward: ward,
                locale: locale,
                margin: margin,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict follow up audit in status draft.
    static func newStrictFollowUpAudit(_ code: String, title: String) -> StrictFollowUpAudit {
        return StrictFollowUpAudit(
            code: code,
            title: title,
            diagnosisCode: "",
            floorValue: 0.0,
            name: "",
            reviewer: "",
            cost: 0.0,
            ward: "",
            locale: "",
            margin: 0.0,
            maximum: 0.0,
            status: StrictFollowUpAuditStatus.draft
        )
    }
}
