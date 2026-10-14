import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback census target is in its life cycle.
    enum FallbackCensusTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback census target. Its code is unique within a tenant.
    final class FallbackCensusTarget {
        var code: String
        var title: String
        var clinicianID: String
        var threshold: Double
        var source: String
        var priority: Int
        var currency: String
        var status: FallbackCensusTargetStatus

        init(code: String, title: String, clinicianID: String, threshold: Double, source: String, priority: Int, currency: String, status: FallbackCensusTargetStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.threshold = threshold
            self.source = source
            self.priority = priority
            self.currency = currency
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

        func canMoveTo(_ next: FallbackCensusTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackCensusTargetStatus.warming || next == FallbackCensusTargetStatus.ready
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: FallbackCensusTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback census target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback census target") \(code)"
        }

        func projectedLoad() -> Double {
            return ((threshold + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCensusTarget {
            return FallbackCensusTarget(
                code: code,
                title: title,
                clinicianID: clinicianID,
                threshold: threshold,
                source: source,
                priority: priority,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback census target in status idle.
    static func newFallbackCensusTarget(_ code: String, title: String) -> FallbackCensusTarget {
        return FallbackCensusTarget(
            code: code,
            title: title,
            clinicianID: "",
            threshold: 0.0,
            source: "",
            priority: 0,
            currency: "",
            status: FallbackCensusTargetStatus.idle
        )
    }
}
