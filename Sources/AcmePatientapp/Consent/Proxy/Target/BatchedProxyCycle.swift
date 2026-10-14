import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched proxy cycle is in its life cycle.
    enum BatchedProxyCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched proxy cycle as the proxy team keeps it.
    final class BatchedProxyCycle {
        var code: String
        var title: String
        var externalRef: String
        var source: String
        var sequence: Int
        var batchSize: Int
        var approved: Bool
        var status: BatchedProxyCycleStatus

        init(code: String, title: String, externalRef: String, source: String, sequence: Int, batchSize: Int, approved: Bool, status: BatchedProxyCycleStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.source = source
            self.sequence = sequence
            self.batchSize = batchSize
            self.approved = approved
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

        func canMoveTo(_ next: BatchedProxyCycleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedProxyCycleStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: BatchedProxyCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched proxy cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return (Double(sequence) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProxyCycle {
            return BatchedProxyCycle(
                code: code,
                title: title,
                externalRef: externalRef,
                source: source,
                sequence: sequence,
                batchSize: batchSize,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched proxy cycle in status proposed.
    static func newBatchedProxyCycle(_ code: String, title: String) -> BatchedProxyCycle {
        return BatchedProxyCycle(
            code: code,
            title: title,
            externalRef: "",
            source: "",
            sequence: 0,
            batchSize: 0,
            approved: false,
            status: BatchedProxyCycleStatus.proposed
        )
    }
}
