import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy reference range summary is in its life cycle.
    enum LegacyReferenceRangeSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A legacy reference range summary. Its code is unique within a tenant.
    final class LegacyReferenceRangeSummary {
        var code: String
        var label: String
        var dosageMg: Double
        var endsAt: Int
        var ratio: Double
        var region: String
        var pinned: Bool
        var status: LegacyReferenceRangeSummaryStatus

        init(code: String, label: String, dosageMg: Double, endsAt: Int, ratio: Double, region: String, pinned: Bool, status: LegacyReferenceRangeSummaryStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.endsAt = endsAt
            self.ratio = ratio
            self.region = region
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

        func canMoveTo(_ next: LegacyReferenceRangeSummaryStatus) -> Bool {
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
                return next == LegacyReferenceRangeSummaryStatus.published
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

        func moveTo(_ next: LegacyReferenceRangeSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy reference range summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netVolume() -> Double {
            return ((dosageMg - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyReferenceRangeSummary {
            return LegacyReferenceRangeSummary(
                code: code,
                label: label,
                dosageMg: dosageMg,
                endsAt: endsAt,
                ratio: ratio,
                region: region,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy reference range summary in status created.
    static func newLegacyReferenceRangeSummary(_ code: String, label: String) -> LegacyReferenceRangeSummary {
        return LegacyReferenceRangeSummary(
            code: code,
            label: label,
            dosageMg: 0.0,
            endsAt: 0,
            ratio: 0.0,
            region: "",
            pinned: false,
            status: LegacyReferenceRangeSummaryStatus.created
        )
    }
}
