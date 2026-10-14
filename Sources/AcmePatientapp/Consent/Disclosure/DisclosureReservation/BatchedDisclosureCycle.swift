import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched disclosure cycle is in its life cycle.
    enum BatchedDisclosureCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched disclosure cycle. Its code is unique within a tenant.
    final class BatchedDisclosureCycle {
        var code: String
        var name: String
        var cost: Double
        var batchSize: Int
        var minimum: Double
        var status: BatchedDisclosureCycleStatus

        init(code: String, name: String, cost: Double, batchSize: Int, minimum: Double, status: BatchedDisclosureCycleStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.batchSize = batchSize
            self.minimum = minimum
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

        func canMoveTo(_ next: BatchedDisclosureCycleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: BatchedDisclosureCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched disclosure cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedLoad() -> Double {
            return (minimum * cost * 100).rounded() / 100
        }

        func copyValue() -> BatchedDisclosureCycle {
            return BatchedDisclosureCycle(
                code: code,
                name: name,
                cost: cost,
                batchSize: batchSize,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched disclosure cycle in status requested.
    static func newBatchedDisclosureCycle(_ code: String, name: String) -> BatchedDisclosureCycle {
        return BatchedDisclosureCycle(
            code: code,
            name: name,
            cost: 0.0,
            batchSize: 0,
            minimum: 0.0,
            status: BatchedDisclosureCycleStatus.requested
        )
    }
}
