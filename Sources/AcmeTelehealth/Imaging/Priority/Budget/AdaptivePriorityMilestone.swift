import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive priority milestone is in its life cycle.
    enum AdaptivePriorityMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive priority milestone as the priority team keeps it.
    final class AdaptivePriorityMilestone {
        var code: String
        var name: String
        var contactEmail: String
        var attributes: [String: String]
        var reviewer: String
        var updatedAt: Int
        var tags: [String]
        var pinned: Bool
        var patientRef: String
        var status: AdaptivePriorityMilestoneStatus

        init(code: String, name: String, contactEmail: String, attributes: [String: String], reviewer: String, updatedAt: Int, tags: [String], pinned: Bool, patientRef: String, status: AdaptivePriorityMilestoneStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.attributes = attributes
            self.reviewer = reviewer
            self.updatedAt = updatedAt
            self.tags = tags
            self.pinned = pinned
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AdaptivePriorityMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptivePriorityMilestoneStatus.expired
            case .revoked:
                return next == AdaptivePriorityMilestoneStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptivePriorityMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive priority milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> AdaptivePriorityMilestone {
            return AdaptivePriorityMilestone(
                code: code,
                name: name,
                contactEmail: contactEmail,
                attributes: attributes,
                reviewer: reviewer,
                updatedAt: updatedAt,
                tags: tags,
                pinned: pinned,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive priority milestone in status requested.
    static func newAdaptivePriorityMilestone(_ code: String, name: String) -> AdaptivePriorityMilestone {
        return AdaptivePriorityMilestone(
            code: code,
            name: name,
            contactEmail: "",
            attributes: [:],
            reviewer: "",
            updatedAt: 0,
            tags: [],
            pinned: false,
            patientRef: "",
            status: AdaptivePriorityMilestoneStatus.requested
        )
    }
}
