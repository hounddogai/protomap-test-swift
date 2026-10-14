import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted credential digest is in its life cycle.
    enum WeightedCredentialDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted credential digest as the credential team keeps it.
    final class WeightedCredentialDigest {
        var code: String
        var label: String
        var active: Bool
        var retries: Int
        var batchSize: Int
        var status: WeightedCredentialDigestStatus

        init(code: String, label: String, active: Bool, retries: Int, batchSize: Int, status: WeightedCredentialDigestStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.retries = retries
            self.batchSize = batchSize
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

        func canMoveTo(_ next: WeightedCredentialDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == WeightedCredentialDigestStatus.published || next == WeightedCredentialDigestStatus.retired
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

        func moveTo(_ next: WeightedCredentialDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted credential digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCredentialDigest {
            return WeightedCredentialDigest(
                code: code,
                label: label,
                active: active,
                retries: retries,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted credential digest in status created.
    static func newWeightedCredentialDigest(_ code: String, label: String) -> WeightedCredentialDigest {
        return WeightedCredentialDigest(
            code: code,
            label: label,
            active: false,
            retries: 0,
            batchSize: 0,
            status: WeightedCredentialDigestStatus.created
        )
    }
}
