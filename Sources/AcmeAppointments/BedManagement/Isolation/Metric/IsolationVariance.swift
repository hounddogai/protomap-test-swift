import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation variance is in its life cycle.
    enum IsolationVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A isolation variance as the isolation team keeps it.
    final class IsolationVariance {
        var code: String
        var title: String
        var ownerID: String
        var graceDays: Int
        var quantity: Int
        var diagnosisCode: String
        var updatedAt: Int
        var startsAt: Int
        var status: IsolationVarianceStatus

        init(code: String, title: String, ownerID: String, graceDays: Int, quantity: Int, diagnosisCode: String, updatedAt: Int, startsAt: Int, status: IsolationVarianceStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.graceDays = graceDays
            self.quantity = quantity
            self.diagnosisCode = diagnosisCode
            self.updatedAt = updatedAt
            self.startsAt = startsAt
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

        func canMoveTo(_ next: IsolationVarianceStatus) -> Bool {
            switch status {
            case .draft:
                return next == IsolationVarianceStatus.pending || next == IsolationVarianceStatus.active
            case .pending:
                return next == IsolationVarianceStatus.active || next == IsolationVarianceStatus.suspended
            case .active:
                return next == IsolationVarianceStatus.suspended || next == IsolationVarianceStatus.closed
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

        func moveTo(_ next: IsolationVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return ((Double(startsAt) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationVariance {
            return IsolationVariance(
                code: code,
                title: title,
                ownerID: ownerID,
                graceDays: graceDays,
                quantity: quantity,
                diagnosisCode: diagnosisCode,
                updatedAt: updatedAt,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation variance in status draft.
    static func newIsolationVariance(_ code: String, title: String) -> IsolationVariance {
        return IsolationVariance(
            code: code,
            title: title,
            ownerID: "",
            graceDays: 0,
            quantity: 0,
            diagnosisCode: "",
            updatedAt: 0,
            startsAt: 0,
            status: IsolationVarianceStatus.draft
        )
    }
}
