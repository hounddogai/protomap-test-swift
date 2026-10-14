import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered cleaning summary is in its life cycle.
    enum TieredCleaningSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a tiered cleaning summary and its current status.
    final class TieredCleaningSummary {
        var code: String
        var title: String
        var pinned: Bool
        var dosageMg: Double
        var ownerID: String
        var status: TieredCleaningSummaryStatus

        init(code: String, title: String, pinned: Bool, dosageMg: Double, ownerID: String, status: TieredCleaningSummaryStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.dosageMg = dosageMg
            self.ownerID = ownerID
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

        func canMoveTo(_ next: TieredCleaningSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TieredCleaningSummaryStatus.running || next == TieredCleaningSummaryStatus.failed
            case .running:
                return next == TieredCleaningSummaryStatus.done || next == TieredCleaningSummaryStatus.failed
            case .done:
                return next == TieredCleaningSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCleaningSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered cleaning summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> TieredCleaningSummary {
            return TieredCleaningSummary(
                code: code,
                title: title,
                pinned: pinned,
                dosageMg: dosageMg,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered cleaning summary in status new.
    static func newTieredCleaningSummary(_ code: String, title: String) -> TieredCleaningSummary {
        return TieredCleaningSummary(
            code: code,
            title: title,
            pinned: false,
            dosageMg: 0.0,
            ownerID: "",
            status: TieredCleaningSummaryStatus.new
        )
    }
}
