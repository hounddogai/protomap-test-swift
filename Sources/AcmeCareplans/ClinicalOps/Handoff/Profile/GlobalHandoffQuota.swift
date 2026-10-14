import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global handoff quota is in its life cycle.
    enum GlobalHandoffQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global handoff quota as the handoff team keeps it.
    final class GlobalHandoffQuota {
        var code: String
        var title: String
        var diagnosisCode: String
        var encounterID: String
        var archived: Bool
        var priority: Int
        var pinned: Bool
        var country: String
        var createdAt: Int
        var status: GlobalHandoffQuotaStatus

        init(code: String, title: String, diagnosisCode: String, encounterID: String, archived: Bool, priority: Int, pinned: Bool, country: String, createdAt: Int, status: GlobalHandoffQuotaStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.encounterID = encounterID
            self.archived = archived
            self.priority = priority
            self.pinned = pinned
            self.country = country
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalHandoffQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GlobalHandoffQuotaStatus.draining || next == GlobalHandoffQuotaStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalHandoffQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global handoff quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return ((Double(createdAt) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalHandoffQuota {
            return GlobalHandoffQuota(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                encounterID: encounterID,
                archived: archived,
                priority: priority,
                pinned: pinned,
                country: country,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global handoff quota in status idle.
    static func newGlobalHandoffQuota(_ code: String, title: String) -> GlobalHandoffQuota {
        return GlobalHandoffQuota(
            code: code,
            title: title,
            diagnosisCode: "",
            encounterID: "",
            archived: false,
            priority: 0,
            pinned: false,
            country: "",
            createdAt: 0,
            status: GlobalHandoffQuotaStatus.idle
        )
    }
}
