import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered priority summary is in its life cycle.
    enum TieredPrioritySummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A tiered priority summary as the priority team keeps it.
    final class TieredPrioritySummary {
        var code: String
        var title: String
        var limit: Int
        var version: Int
        var checksum: String
        var region: String
        var encounterID: String
        var quantity: Int
        var pinned: Bool
        var status: TieredPrioritySummaryStatus

        init(code: String, title: String, limit: Int, version: Int, checksum: String, region: String, encounterID: String, quantity: Int, pinned: Bool, status: TieredPrioritySummaryStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.version = version
            self.checksum = checksum
            self.region = region
            self.encounterID = encounterID
            self.quantity = quantity
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredPrioritySummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == TieredPrioritySummaryStatus.published || next == TieredPrioritySummaryStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: TieredPrioritySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered priority summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("tiered priority summary") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(version) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> TieredPrioritySummary {
            return TieredPrioritySummary(
                code: code,
                title: title,
                limit: limit,
                version: version,
                checksum: checksum,
                region: region,
                encounterID: encounterID,
                quantity: quantity,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered priority summary in status created.
    static func newTieredPrioritySummary(_ code: String, title: String) -> TieredPrioritySummary {
        return TieredPrioritySummary(
            code: code,
            title: title,
            limit: 0,
            version: 0,
            checksum: "",
            region: "",
            encounterID: "",
            quantity: 0,
            pinned: false,
            status: TieredPrioritySummaryStatus.created
        )
    }
}
