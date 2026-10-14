import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim mapping is in its life cycle.
    enum ClaimMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A claim mapping as the claim team keeps it.
    final class ClaimMapping {
        var code: String
        var name: String
        var retries: Int
        var margin: Double
        var archived: Bool
        var durationMinutes: Int
        var status: ClaimMappingStatus

        init(code: String, name: String, retries: Int, margin: Double, archived: Bool, durationMinutes: Int, status: ClaimMappingStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.margin = margin
            self.archived = archived
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: ClaimMappingStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ClaimMappingStatus.withdrawn
            case .approved:
                return next == ClaimMappingStatus.rejected
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

        func moveTo(_ next: ClaimMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return ((Double(retries) + margin) * 100).rounded() / 100
        }

        func copyValue() -> ClaimMapping {
            return ClaimMapping(
                code: code,
                name: name,
                retries: retries,
                margin: margin,
                archived: archived,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim mapping in status proposed.
    static func newClaimMapping(_ code: String, name: String) -> ClaimMapping {
        return ClaimMapping(
            code: code,
            name: name,
            retries: 0,
            margin: 0.0,
            archived: false,
            durationMinutes: 0,
            status: ClaimMappingStatus.proposed
        )
    }
}
