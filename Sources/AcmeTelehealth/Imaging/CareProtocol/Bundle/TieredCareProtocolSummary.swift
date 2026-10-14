import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered care protocol summary is in its life cycle.
    enum TieredCareProtocolSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered care protocol summary. Its code is unique within a tenant.
    final class TieredCareProtocolSummary {
        var code: String
        var name: String
        var country: String
        var ownerID: String
        var revision: Int
        var status: TieredCareProtocolSummaryStatus

        init(code: String, name: String, country: String, ownerID: String, revision: Int, status: TieredCareProtocolSummaryStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.ownerID = ownerID
            self.revision = revision
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

        func canMoveTo(_ next: TieredCareProtocolSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TieredCareProtocolSummaryStatus.running || next == TieredCareProtocolSummaryStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TieredCareProtocolSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCareProtocolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care protocol summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> TieredCareProtocolSummary {
            return TieredCareProtocolSummary(
                code: code,
                name: name,
                country: country,
                ownerID: ownerID,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered care protocol summary in status new.
    static func newTieredCareProtocolSummary(_ code: String, name: String) -> TieredCareProtocolSummary {
        return TieredCareProtocolSummary(
            code: code,
            name: name,
            country: "",
            ownerID: "",
            revision: 0,
            status: TieredCareProtocolSummaryStatus.new
        )
    }
}
