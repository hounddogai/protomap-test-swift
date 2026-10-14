import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling statement group is in its life cycle.
    enum RollingStatementGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling statement group as the statement team keeps it.
    final class RollingStatementGroup {
        var code: String
        var title: String
        var currency: String
        var ward: String
        var clinicianID: String
        var summary: String
        var acuity: Int
        var version: Int
        var status: RollingStatementGroupStatus

        init(code: String, title: String, currency: String, ward: String, clinicianID: String, summary: String, acuity: Int, version: Int, status: RollingStatementGroupStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.ward = ward
            self.clinicianID = clinicianID
            self.summary = summary
            self.acuity = acuity
            self.version = version
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

        func canMoveTo(_ next: RollingStatementGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RollingStatementGroupStatus.reopened || next == RollingStatementGroupStatus.archived
            case .resolved:
                return next == RollingStatementGroupStatus.archived
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

        func moveTo(_ next: RollingStatementGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling statement group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("rolling statement group") \(code)"
        }

        func effectiveTotal() -> Double {
            return (Double(version) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> RollingStatementGroup {
            return RollingStatementGroup(
                code: code,
                title: title,
                currency: currency,
                ward: ward,
                clinicianID: clinicianID,
                summary: summary,
                acuity: acuity,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling statement group in status open.
    static func newRollingStatementGroup(_ code: String, title: String) -> RollingStatementGroup {
        return RollingStatementGroup(
            code: code,
            title: title,
            currency: "",
            ward: "",
            clinicianID: "",
            summary: "",
            acuity: 0,
            version: 0,
            status: RollingStatementGroupStatus.`open`
        )
    }
}
