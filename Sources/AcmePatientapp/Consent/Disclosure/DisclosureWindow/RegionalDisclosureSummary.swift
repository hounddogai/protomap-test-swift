import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional disclosure summary is in its life cycle.
    enum RegionalDisclosureSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a regional disclosure summary and its current status.
    final class RegionalDisclosureSummary {
        var code: String
        var label: String
        var minimum: Double
        var batchSize: Int
        var country: String
        var status: RegionalDisclosureSummaryStatus

        init(code: String, label: String, minimum: Double, batchSize: Int, country: String, status: RegionalDisclosureSummaryStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.batchSize = batchSize
            self.country = country
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

        func canMoveTo(_ next: RegionalDisclosureSummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RegionalDisclosureSummaryStatus.published
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

        func moveTo(_ next: RegionalDisclosureSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional disclosure summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netVolume() -> Double {
            return ((Double(batchSize) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDisclosureSummary {
            return RegionalDisclosureSummary(
                code: code,
                label: label,
                minimum: minimum,
                batchSize: batchSize,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional disclosure summary in status created.
    static func newRegionalDisclosureSummary(_ code: String, label: String) -> RegionalDisclosureSummary {
        return RegionalDisclosureSummary(
            code: code,
            label: label,
            minimum: 0.0,
            batchSize: 0,
            country: "",
            status: RegionalDisclosureSummaryStatus.created
        )
    }
}
