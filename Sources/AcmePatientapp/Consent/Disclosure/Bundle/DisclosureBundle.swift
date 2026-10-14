import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure bundle is in its life cycle.
    enum DisclosureBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A disclosure bundle as the disclosure team keeps it.
    final class DisclosureBundle {
        var code: String
        var title: String
        var description: String
        var cost: Double
        var attempts: Int
        var updatedAt: Int
        var encounterID: String
        var bed: String
        var archived: Bool
        var approved: Bool
        var status: DisclosureBundleStatus

        init(code: String, title: String, description: String, cost: Double, attempts: Int, updatedAt: Int, encounterID: String, bed: String, archived: Bool, approved: Bool, status: DisclosureBundleStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.cost = cost
            self.attempts = attempts
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.bed = bed
            self.archived = archived
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureBundleStatus) -> Bool {
            switch status {
            case .new:
                return next == DisclosureBundleStatus.queued || next == DisclosureBundleStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DisclosureBundleStatus.done || next == DisclosureBundleStatus.failed
            case .done:
                return next == DisclosureBundleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("disclosure bundle") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((cost - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureBundle {
            return DisclosureBundle(
                code: code,
                title: title,
                description: description,
                cost: cost,
                attempts: attempts,
                updatedAt: updatedAt,
                encounterID: encounterID,
                bed: bed,
                archived: archived,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a disclosure bundle in status new.
    static func newDisclosureBundle(_ code: String, title: String) -> DisclosureBundle {
        return DisclosureBundle(
            code: code,
            title: title,
            description: "",
            cost: 0.0,
            attempts: 0,
            updatedAt: 0,
            encounterID: "",
            bed: "",
            archived: false,
            approved: false,
            status: DisclosureBundleStatus.new
        )
    }
}
