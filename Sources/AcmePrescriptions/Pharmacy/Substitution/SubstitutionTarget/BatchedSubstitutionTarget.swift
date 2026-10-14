import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched substitution target is in its life cycle.
    enum BatchedSubstitutionTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a batched substitution target and its current status.
    final class BatchedSubstitutionTarget {
        var code: String
        var label: String
        var threshold: Double
        var channel: String
        var rate: Double
        var facility: String
        var version: Int
        var status: BatchedSubstitutionTargetStatus

        init(code: String, label: String, threshold: Double, channel: String, rate: Double, facility: String, version: Int, status: BatchedSubstitutionTargetStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.channel = channel
            self.rate = rate
            self.facility = facility
            self.version = version
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

        func canMoveTo(_ next: BatchedSubstitutionTargetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedSubstitutionTargetStatus.revoked || next == BatchedSubstitutionTargetStatus.expired
            case .revoked:
                return next == BatchedSubstitutionTargetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSubstitutionTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched substitution target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return ((rate + threshold) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSubstitutionTarget {
            return BatchedSubstitutionTarget(
                code: code,
                label: label,
                threshold: threshold,
                channel: channel,
                rate: rate,
                facility: facility,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched substitution target in status requested.
    static func newBatchedSubstitutionTarget(_ code: String, label: String) -> BatchedSubstitutionTarget {
        return BatchedSubstitutionTarget(
            code: code,
            label: label,
            threshold: 0.0,
            channel: "",
            rate: 0.0,
            facility: "",
            version: 0,
            status: BatchedSubstitutionTargetStatus.requested
        )
    }
}
