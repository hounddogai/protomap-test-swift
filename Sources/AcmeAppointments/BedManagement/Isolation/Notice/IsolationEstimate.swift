import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation estimate is in its life cycle.
    enum IsolationEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A isolation estimate. Its code is unique within a tenant.
    final class IsolationEstimate {
        var code: String
        var title: String
        var weight: Double
        var acuity: Int
        var attempts: Int
        var payer: String
        var ward: String
        var status: IsolationEstimateStatus

        init(code: String, title: String, weight: Double, acuity: Int, attempts: Int, payer: String, ward: String, status: IsolationEstimateStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.acuity = acuity
            self.attempts = attempts
            self.payer = payer
            self.ward = ward
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

        func canMoveTo(_ next: IsolationEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == IsolationEstimateStatus.archived
            case .inReview:
                return next == IsolationEstimateStatus.resolved || next == IsolationEstimateStatus.reopened
            case .resolved:
                return next == IsolationEstimateStatus.reopened
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

        func moveTo(_ next: IsolationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedExposure() -> Double {
            return ((weight - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationEstimate {
            return IsolationEstimate(
                code: code,
                title: title,
                weight: weight,
                acuity: acuity,
                attempts: attempts,
                payer: payer,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a isolation estimate in status open.
    static func newIsolationEstimate(_ code: String, title: String) -> IsolationEstimate {
        return IsolationEstimate(
            code: code,
            title: title,
            weight: 0.0,
            acuity: 0,
            attempts: 0,
            payer: "",
            ward: "",
            status: IsolationEstimateStatus.`open`
        )
    }
}
