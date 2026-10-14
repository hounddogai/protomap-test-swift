import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback revocation summary is in its life cycle.
    enum FallbackRevocationSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback revocation summary as the revocation team keeps it.
    final class FallbackRevocationSummary {
        var code: String
        var label: String
        var updatedAt: Int
        var ratio: Double
        var currency: String
        var tags: [String]
        var weight: Double
        var description: String
        var priority: Int
        var status: FallbackRevocationSummaryStatus

        init(code: String, label: String, updatedAt: Int, ratio: Double, currency: String, tags: [String], weight: Double, description: String, priority: Int, status: FallbackRevocationSummaryStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.ratio = ratio
            self.currency = currency
            self.tags = tags
            self.weight = weight
            self.description = description
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackRevocationSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackRevocationSummaryStatus.stopped
            case .draining:
                return next == FallbackRevocationSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRevocationSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback revocation summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("fallback revocation summary") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(updatedAt) + weight) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRevocationSummary {
            return FallbackRevocationSummary(
                code: code,
                label: label,
                updatedAt: updatedAt,
                ratio: ratio,
                currency: currency,
                tags: tags,
                weight: weight,
                description: description,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback revocation summary in status idle.
    static func newFallbackRevocationSummary(_ code: String, label: String) -> FallbackRevocationSummary {
        return FallbackRevocationSummary(
            code: code,
            label: label,
            updatedAt: 0,
            ratio: 0.0,
            currency: "",
            tags: [],
            weight: 0.0,
            description: "",
            priority: 0,
            status: FallbackRevocationSummaryStatus.idle
        )
    }
}
