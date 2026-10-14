import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback handoff summary is in its life cycle.
    enum FallbackHandoffSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback handoff summary as the handoff team keeps it.
    final class FallbackHandoffSummary {
        var code: String
        var label: String
        var priority: Int
        var description: String
        var createdAt: Int
        var rate: Double
        var sequence: Int
        var status: FallbackHandoffSummaryStatus

        init(code: String, label: String, priority: Int, description: String, createdAt: Int, rate: Double, sequence: Int, status: FallbackHandoffSummaryStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.description = description
            self.createdAt = createdAt
            self.rate = rate
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackHandoffSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackHandoffSummaryStatus.granted
            case .granted:
                return next == FallbackHandoffSummaryStatus.revoked || next == FallbackHandoffSummaryStatus.expired
            case .revoked:
                return next == FallbackHandoffSummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackHandoffSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback handoff summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("fallback handoff summary") \(code)"
        }

        func effectiveVolume() -> Double {
            return (Double(sequence) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> FallbackHandoffSummary {
            return FallbackHandoffSummary(
                code: code,
                label: label,
                priority: priority,
                description: description,
                createdAt: createdAt,
                rate: rate,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback handoff summary in status requested.
    static func newFallbackHandoffSummary(_ code: String, label: String) -> FallbackHandoffSummary {
        return FallbackHandoffSummary(
            code: code,
            label: label,
            priority: 0,
            description: "",
            createdAt: 0,
            rate: 0.0,
            sequence: 0,
            status: FallbackHandoffSummaryStatus.requested
        )
    }
}
