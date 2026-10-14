import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol summary is in its life cycle.
    enum CareProtocolSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care protocol summary as the care protocol team keeps it.
    final class CareProtocolSummary {
        var code: String
        var label: String
        var discount: Double
        var startsAt: Int
        var phone: String
        var status: CareProtocolSummaryStatus

        init(code: String, label: String, discount: Double, startsAt: Int, phone: String, status: CareProtocolSummaryStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.startsAt = startsAt
            self.phone = phone
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

        func canMoveTo(_ next: CareProtocolSummaryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CareProtocolSummaryStatus.closed
            case .active:
                return next == CareProtocolSummaryStatus.suspended || next == CareProtocolSummaryStatus.closed
            case .suspended:
                return next == CareProtocolSummaryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return ((discount + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolSummary {
            return CareProtocolSummary(
                code: code,
                label: label,
                discount: discount,
                startsAt: startsAt,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol summary in status draft.
    static func newCareProtocolSummary(_ code: String, label: String) -> CareProtocolSummary {
        return CareProtocolSummary(
            code: code,
            label: label,
            discount: 0.0,
            startsAt: 0,
            phone: "",
            status: CareProtocolSummaryStatus.draft
        )
    }
}
