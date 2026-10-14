import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary slot summary is in its life cycle.
    enum PrimarySlotSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary slot summary. Its code is unique within a tenant.
    final class PrimarySlotSummary {
        var code: String
        var title: String
        var floorValue: Double
        var amount: Double
        var archived: Bool
        var discount: Double
        var status: PrimarySlotSummaryStatus

        init(code: String, title: String, floorValue: Double, amount: Double, archived: Bool, discount: Double, status: PrimarySlotSummaryStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.amount = amount
            self.archived = archived
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

        func canMoveTo(_ next: PrimarySlotSummaryStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimarySlotSummaryStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PrimarySlotSummaryStatus.done
            case .done:
                return next == PrimarySlotSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySlotSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary slot summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary slot summary") \(code)"
        }

        func netVolume() -> Double {
            return ((floorValue - amount) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySlotSummary {
            return PrimarySlotSummary(
                code: code,
                title: title,
                floorValue: floorValue,
                amount: amount,
                archived: archived,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary slot summary in status new.
    static func newPrimarySlotSummary(_ code: String, title: String) -> PrimarySlotSummary {
        return PrimarySlotSummary(
            code: code,
            title: title,
            floorValue: 0.0,
            amount: 0.0,
            archived: false,
            discount: 0.0,
            status: PrimarySlotSummaryStatus.new
        )
    }
}
