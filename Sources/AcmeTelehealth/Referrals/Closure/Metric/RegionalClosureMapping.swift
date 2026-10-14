import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional closure mapping is in its life cycle.
    enum RegionalClosureMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional closure mapping. Its code is unique within a tenant.
    final class RegionalClosureMapping {
        var code: String
        var title: String
        var unit: String
        var bed: String
        var diagnosisCode: String
        var amount: Double
        var status: RegionalClosureMappingStatus

        init(code: String, title: String, unit: String, bed: String, diagnosisCode: String, amount: Double, status: RegionalClosureMappingStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.bed = bed
            self.diagnosisCode = diagnosisCode
            self.amount = amount
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

        func canMoveTo(_ next: RegionalClosureMappingStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalClosureMappingStatus.resolved
            case .inReview:
                return next == RegionalClosureMappingStatus.resolved
            case .resolved:
                return next == RegionalClosureMappingStatus.reopened
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

        func moveTo(_ next: RegionalClosureMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional closure mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional closure mapping") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RegionalClosureMapping {
            return RegionalClosureMapping(
                code: code,
                title: title,
                unit: unit,
                bed: bed,
                diagnosisCode: diagnosisCode,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional closure mapping in status open.
    static func newRegionalClosureMapping(_ code: String, title: String) -> RegionalClosureMapping {
        return RegionalClosureMapping(
            code: code,
            title: title,
            unit: "",
            bed: "",
            diagnosisCode: "",
            amount: 0.0,
            status: RegionalClosureMappingStatus.`open`
        )
    }
}
