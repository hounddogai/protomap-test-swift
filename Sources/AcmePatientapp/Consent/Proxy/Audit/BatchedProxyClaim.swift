import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched proxy claim is in its life cycle.
    enum BatchedProxyClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched proxy claim. Its code is unique within a tenant.
    final class BatchedProxyClaim {
        var code: String
        var label: String
        var revision: Int
        var capacity: Int
        var createdAt: Int
        var phone: String
        var amount: Double
        var source: String
        var status: BatchedProxyClaimStatus

        init(code: String, label: String, revision: Int, capacity: Int, createdAt: Int, phone: String, amount: Double, source: String, status: BatchedProxyClaimStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.capacity = capacity
            self.createdAt = createdAt
            self.phone = phone
            self.amount = amount
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedProxyClaimStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: BatchedProxyClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched proxy claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return ((Double(revision) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProxyClaim {
            return BatchedProxyClaim(
                code: code,
                label: label,
                revision: revision,
                capacity: capacity,
                createdAt: createdAt,
                phone: phone,
                amount: amount,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched proxy claim in status open.
    static func newBatchedProxyClaim(_ code: String, label: String) -> BatchedProxyClaim {
        return BatchedProxyClaim(
            code: code,
            label: label,
            revision: 0,
            capacity: 0,
            createdAt: 0,
            phone: "",
            amount: 0.0,
            source: "",
            status: BatchedProxyClaimStatus.`open`
        )
    }
}
