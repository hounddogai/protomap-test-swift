import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation group is in its life cycle.
    enum IsolationGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One isolation group, with what the planners need to act on it.
    final class IsolationGroup {
        var code: String
        var title: String
        var retries: Int
        var refills: Int
        var checksum: String
        var discount: Double
        var name: String
        var dosageMg: Double
        var status: IsolationGroupStatus

        init(code: String, title: String, retries: Int, refills: Int, checksum: String, discount: Double, name: String, dosageMg: Double, status: IsolationGroupStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.refills = refills
            self.checksum = checksum
            self.discount = discount
            self.name = name
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: IsolationGroupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == IsolationGroupStatus.inReview
            case .inReview:
                return next == IsolationGroupStatus.resolved || next == IsolationGroupStatus.archived
            case .resolved:
                return next == IsolationGroupStatus.reopened || next == IsolationGroupStatus.archived
            case .reopened:
                return next == IsolationGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("isolation group") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(refills) + discount) * 100).rounded() / 100
        }

        func copyValue() -> IsolationGroup {
            return IsolationGroup(
                code: code,
                title: title,
                retries: retries,
                refills: refills,
                checksum: checksum,
                discount: discount,
                name: name,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation group in status open.
    static func newIsolationGroup(_ code: String, title: String) -> IsolationGroup {
        return IsolationGroup(
            code: code,
            title: title,
            retries: 0,
            refills: 0,
            checksum: "",
            discount: 0.0,
            name: "",
            dosageMg: 0.0,
            status: IsolationGroupStatus.`open`
        )
    }
}
