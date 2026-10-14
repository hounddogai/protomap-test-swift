import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional care gap milestone is in its life cycle.
    enum RegionalCareGapMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional care gap milestone. Its code is unique within a tenant.
    final class RegionalCareGapMilestone {
        var code: String
        var name: String
        var pinned: Bool
        var title: String
        var notes: String
        var archived: Bool
        var margin: Double
        var status: RegionalCareGapMilestoneStatus

        init(code: String, name: String, pinned: Bool, title: String, notes: String, archived: Bool, margin: Double, status: RegionalCareGapMilestoneStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.title = title
            self.notes = notes
            self.archived = archived
            self.margin = margin
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

        func canMoveTo(_ next: RegionalCareGapMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
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

        func moveTo(_ next: RegionalCareGapMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care gap milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> RegionalCareGapMilestone {
            return RegionalCareGapMilestone(
                code: code,
                name: name,
                pinned: pinned,
                title: title,
                notes: notes,
                archived: archived,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional care gap milestone in status requested.
    static func newRegionalCareGapMilestone(_ code: String, name: String) -> RegionalCareGapMilestone {
        return RegionalCareGapMilestone(
            code: code,
            name: name,
            pinned: false,
            title: "",
            notes: "",
            archived: false,
            margin: 0.0,
            status: RegionalCareGapMilestoneStatus.requested
        )
    }
}
