import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction mapping is in its life cycle.
    enum InteractionMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A interaction mapping. Its code is unique within a tenant.
    final class InteractionMapping {
        var code: String
        var title: String
        var endsAt: Int
        var checksum: String
        var graceDays: Int
        var status: InteractionMappingStatus

        init(code: String, title: String, endsAt: Int, checksum: String, graceDays: Int, status: InteractionMappingStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.checksum = checksum
            self.graceDays = graceDays
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

        func canMoveTo(_ next: InteractionMappingStatus) -> Bool {
            switch status {
            case .proposed:
                return next == InteractionMappingStatus.approved
            case .approved:
                return next == InteractionMappingStatus.rejected || next == InteractionMappingStatus.withdrawn
            case .rejected:
                return next == InteractionMappingStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("interaction mapping") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(endsAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> InteractionMapping {
            return InteractionMapping(
                code: code,
                title: title,
                endsAt: endsAt,
                checksum: checksum,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a interaction mapping in status proposed.
    static func newInteractionMapping(_ code: String, title: String) -> InteractionMapping {
        return InteractionMapping(
            code: code,
            title: title,
            endsAt: 0,
            checksum: "",
            graceDays: 0,
            status: InteractionMappingStatus.proposed
        )
    }
}
