import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance quota is in its life cycle.
    enum RemittanceQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A remittance quota. Its code is unique within a tenant.
    final class RemittanceQuota {
        var code: String
        var name: String
        var approved: Bool
        var batchSize: Int
        var capacity: Int
        var pinned: Bool
        var createdAt: Int
        var reviewer: String
        var status: RemittanceQuotaStatus

        init(code: String, name: String, approved: Bool, batchSize: Int, capacity: Int, pinned: Bool, createdAt: Int, reviewer: String, status: RemittanceQuotaStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.batchSize = batchSize
            self.capacity = capacity
            self.pinned = pinned
            self.createdAt = createdAt
            self.reviewer = reviewer
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

        func canMoveTo(_ next: RemittanceQuotaStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RemittanceQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("remittance quota") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(batchSize) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceQuota {
            return RemittanceQuota(
                code: code,
                name: name,
                approved: approved,
                batchSize: batchSize,
                capacity: capacity,
                pinned: pinned,
                createdAt: createdAt,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance quota in status created.
    static func newRemittanceQuota(_ code: String, name: String) -> RemittanceQuota {
        return RemittanceQuota(
            code: code,
            name: name,
            approved: false,
            batchSize: 0,
            capacity: 0,
            pinned: false,
            createdAt: 0,
            reviewer: "",
            status: RemittanceQuotaStatus.created
        )
    }
}
