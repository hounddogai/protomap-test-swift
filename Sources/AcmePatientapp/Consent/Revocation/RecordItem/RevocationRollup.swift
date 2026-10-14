import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation rollup is in its life cycle.
    enum RevocationRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a revocation rollup and its current status.
    final class RevocationRollup {
        var code: String
        var label: String
        var acuity: Int
        var minimum: Double
        var bed: String
        var ownerID: String
        var status: RevocationRollupStatus

        init(code: String, label: String, acuity: Int, minimum: Double, bed: String, ownerID: String, status: RevocationRollupStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.minimum = minimum
            self.bed = bed
            self.ownerID = ownerID
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

        func canMoveTo(_ next: RevocationRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RevocationRollupStatus.ready || next == RevocationRollupStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: RevocationRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation rollup") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((minimum + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationRollup {
            return RevocationRollup(
                code: code,
                label: label,
                acuity: acuity,
                minimum: minimum,
                bed: bed,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a revocation rollup in status idle.
    static func newRevocationRollup(_ code: String, label: String) -> RevocationRollup {
        return RevocationRollup(
            code: code,
            label: label,
            acuity: 0,
            minimum: 0.0,
            bed: "",
            ownerID: "",
            status: RevocationRollupStatus.idle
        )
    }
}
