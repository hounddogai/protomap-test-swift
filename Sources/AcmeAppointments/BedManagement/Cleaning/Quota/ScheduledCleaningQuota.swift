import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled cleaning quota is in its life cycle.
    enum ScheduledCleaningQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled cleaning quota. Its code is unique within a tenant.
    final class ScheduledCleaningQuota {
        var code: String
        var name: String
        var checksum: String
        var pinned: Bool
        var externalRef: String
        var tags: [String]
        var facility: String
        var graceDays: Int
        var priority: Int
        var status: ScheduledCleaningQuotaStatus

        init(code: String, name: String, checksum: String, pinned: Bool, externalRef: String, tags: [String], facility: String, graceDays: Int, priority: Int, status: ScheduledCleaningQuotaStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.pinned = pinned
            self.externalRef = externalRef
            self.tags = tags
            self.facility = facility
            self.graceDays = graceDays
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledCleaningQuotaStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ScheduledCleaningQuotaStatus.suspended || next == ScheduledCleaningQuotaStatus.closed
            case .suspended:
                return next == ScheduledCleaningQuotaStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCleaningQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled cleaning quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(priority) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCleaningQuota {
            return ScheduledCleaningQuota(
                code: code,
                name: name,
                checksum: checksum,
                pinned: pinned,
                externalRef: externalRef,
                tags: tags,
                facility: facility,
                graceDays: graceDays,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a scheduled cleaning quota in status draft.
    static func newScheduledCleaningQuota(_ code: String, name: String) -> ScheduledCleaningQuota {
        return ScheduledCleaningQuota(
            code: code,
            name: name,
            checksum: "",
            pinned: false,
            externalRef: "",
            tags: [],
            facility: "",
            graceDays: 0,
            priority: 0,
            status: ScheduledCleaningQuotaStatus.draft
        )
    }
}
