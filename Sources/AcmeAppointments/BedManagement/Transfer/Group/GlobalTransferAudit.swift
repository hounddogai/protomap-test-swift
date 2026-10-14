import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global transfer audit is in its life cycle.
    enum GlobalTransferAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global transfer audit, with what the planners need to act on it.
    final class GlobalTransferAudit {
        var code: String
        var name: String
        var windowDays: Int
        var checksum: String
        var score: Double
        var externalRef: String
        var approved: Bool
        var ownerID: String
        var discount: Double
        var threshold: Double
        var timezone: String
        var status: GlobalTransferAuditStatus

        init(code: String, name: String, windowDays: Int, checksum: String, score: Double, externalRef: String, approved: Bool, ownerID: String, discount: Double, threshold: Double, timezone: String, status: GlobalTransferAuditStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.checksum = checksum
            self.score = score
            self.externalRef = externalRef
            self.approved = approved
            self.ownerID = ownerID
            self.discount = discount
            self.threshold = threshold
            self.timezone = timezone
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

        func canMoveTo(_ next: GlobalTransferAuditStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalTransferAuditStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == GlobalTransferAuditStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalTransferAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global transfer audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return (Double(windowDays) * threshold * 100).rounded() / 100
        }

        func copyValue() -> GlobalTransferAudit {
            return GlobalTransferAudit(
                code: code,
                name: name,
                windowDays: windowDays,
                checksum: checksum,
                score: score,
                externalRef: externalRef,
                approved: approved,
                ownerID: ownerID,
                discount: discount,
                threshold: threshold,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global transfer audit in status proposed.
    static func newGlobalTransferAudit(_ code: String, name: String) -> GlobalTransferAudit {
        return GlobalTransferAudit(
            code: code,
            name: name,
            windowDays: 0,
            checksum: "",
            score: 0.0,
            externalRef: "",
            approved: false,
            ownerID: "",
            discount: 0.0,
            threshold: 0.0,
            timezone: "",
            status: GlobalTransferAuditStatus.proposed
        )
    }
}
