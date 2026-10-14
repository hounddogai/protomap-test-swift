import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending program target is in its life cycle.
    enum PendingProgramTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending program target as the program team keeps it.
    final class PendingProgramTarget {
        var code: String
        var name: String
        var cost: Double
        var attributes: [String: String]
        var discount: Double
        var archived: Bool
        var status: PendingProgramTargetStatus

        init(code: String, name: String, cost: Double, attributes: [String: String], discount: Double, archived: Bool, status: PendingProgramTargetStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.attributes = attributes
            self.discount = discount
            self.archived = archived
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

        func canMoveTo(_ next: PendingProgramTargetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: PendingProgramTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending program target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending program target") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveVolume() -> Double {
            return ((discount - cost) * 100).rounded() / 100
        }

        func copyValue() -> PendingProgramTarget {
            return PendingProgramTarget(
                code: code,
                name: name,
                cost: cost,
                attributes: attributes,
                discount: discount,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending program target in status requested.
    static func newPendingProgramTarget(_ code: String, name: String) -> PendingProgramTarget {
        return PendingProgramTarget(
            code: code,
            name: name,
            cost: 0.0,
            attributes: [:],
            discount: 0.0,
            archived: false,
            status: PendingProgramTargetStatus.requested
        )
    }
}
