import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure summary is in its life cycle.
    enum DisclosureSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One disclosure summary, with what the planners need to act on it.
    final class DisclosureSummary {
        var code: String
        var label: String
        var updatedAt: Int
        var version: Int
        var createdAt: Int
        var status: DisclosureSummaryStatus

        init(code: String, label: String, updatedAt: Int, version: Int, createdAt: Int, status: DisclosureSummaryStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.version = version
            self.createdAt = createdAt
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

        func canMoveTo(_ next: DisclosureSummaryStatus) -> Bool {
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
                return next == DisclosureSummaryStatus.published
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

        func moveTo(_ next: DisclosureSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return (Double(version) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureSummary {
            return DisclosureSummary(
                code: code,
                label: label,
                updatedAt: updatedAt,
                version: version,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure summary in status created.
    static func newDisclosureSummary(_ code: String, label: String) -> DisclosureSummary {
        return DisclosureSummary(
            code: code,
            label: label,
            updatedAt: 0,
            version: 0,
            createdAt: 0,
            status: DisclosureSummaryStatus.created
        )
    }
}
