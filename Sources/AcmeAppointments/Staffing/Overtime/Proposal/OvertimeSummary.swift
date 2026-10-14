import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime summary is in its life cycle.
    enum OvertimeSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A overtime summary. Its code is unique within a tenant.
    final class OvertimeSummary {
        var code: String
        var title: String
        var ratio: Double
        var pinned: Bool
        var floorValue: Double
        var ownerID: String
        var approved: Bool
        var discount: Double
        var status: OvertimeSummaryStatus

        init(code: String, title: String, ratio: Double, pinned: Bool, floorValue: Double, ownerID: String, approved: Bool, discount: Double, status: OvertimeSummaryStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.pinned = pinned
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.approved = approved
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OvertimeSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == OvertimeSummaryStatus.done || next == OvertimeSummaryStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == OvertimeSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("overtime summary") \(code)"
        }

        func projectedTotal() -> Double {
            return (floorValue * discount * 100).rounded() / 100
        }

        func copyValue() -> OvertimeSummary {
            return OvertimeSummary(
                code: code,
                title: title,
                ratio: ratio,
                pinned: pinned,
                floorValue: floorValue,
                ownerID: ownerID,
                approved: approved,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime summary in status new.
    static func newOvertimeSummary(_ code: String, title: String) -> OvertimeSummary {
        return OvertimeSummary(
            code: code,
            title: title,
            ratio: 0.0,
            pinned: false,
            floorValue: 0.0,
            ownerID: "",
            approved: false,
            discount: 0.0,
            status: OvertimeSummaryStatus.new
        )
    }
}
