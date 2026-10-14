import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional substitution record is in its life cycle.
    enum RegionalSubstitutionRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional substitution record as the substitution team keeps it.
    final class RegionalSubstitutionRecord {
        var code: String
        var title: String
        var reviewer: String
        var procedureCode: String
        var ceiling: Double
        var acuity: Int
        var timezone: String
        var maximum: Double
        var refills: Int
        var ratio: Double
        var status: RegionalSubstitutionRecordStatus

        init(code: String, title: String, reviewer: String, procedureCode: String, ceiling: Double, acuity: Int, timezone: String, maximum: Double, refills: Int, ratio: Double, status: RegionalSubstitutionRecordStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.ceiling = ceiling
            self.acuity = acuity
            self.timezone = timezone
            self.maximum = maximum
            self.refills = refills
            self.ratio = ratio
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

        func canMoveTo(_ next: RegionalSubstitutionRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalSubstitutionRecordStatus.inReview
            case .inReview:
                return next == RegionalSubstitutionRecordStatus.archived
            case .resolved:
                return next == RegionalSubstitutionRecordStatus.reopened
            case .reopened:
                return next == RegionalSubstitutionRecordStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalSubstitutionRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional substitution record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional substitution record") \(code)"
        }

        func projectedExposure() -> Double {
            return ((ratio + maximum) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSubstitutionRecord {
            return RegionalSubstitutionRecord(
                code: code,
                title: title,
                reviewer: reviewer,
                procedureCode: procedureCode,
                ceiling: ceiling,
                acuity: acuity,
                timezone: timezone,
                maximum: maximum,
                refills: refills,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional substitution record in status open.
    static func newRegionalSubstitutionRecord(_ code: String, title: String) -> RegionalSubstitutionRecord {
        return RegionalSubstitutionRecord(
            code: code,
            title: title,
            reviewer: "",
            procedureCode: "",
            ceiling: 0.0,
            acuity: 0,
            timezone: "",
            maximum: 0.0,
            refills: 0,
            ratio: 0.0,
            status: RegionalSubstitutionRecordStatus.`open`
        )
    }
}
