import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual float pool summary is in its life cycle.
    enum ManualFloatPoolSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual float pool summary. Its code is unique within a tenant.
    final class ManualFloatPoolSummary {
        var code: String
        var name: String
        var maximum: Double
        var label: String
        var score: Double
        var status: ManualFloatPoolSummaryStatus

        init(code: String, name: String, maximum: Double, label: String, score: Double, status: ManualFloatPoolSummaryStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.label = label
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualFloatPoolSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualFloatPoolSummaryStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ManualFloatPoolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual float pool summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func netTotal() -> Double {
            return ((maximum - score) * 100).rounded() / 100
        }

        func copyValue() -> ManualFloatPoolSummary {
            return ManualFloatPoolSummary(
                code: code,
                name: name,
                maximum: maximum,
                label: label,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual float pool summary in status proposed.
    static func newManualFloatPoolSummary(_ code: String, name: String) -> ManualFloatPoolSummary {
        return ManualFloatPoolSummary(
            code: code,
            name: name,
            maximum: 0.0,
            label: "",
            score: 0.0,
            status: ManualFloatPoolSummaryStatus.proposed
        )
    }
}
