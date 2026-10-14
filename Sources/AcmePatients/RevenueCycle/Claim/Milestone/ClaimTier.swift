import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim tier is in its life cycle.
    enum ClaimTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A claim tier. Its code is unique within a tenant.
    final class ClaimTier {
        var code: String
        var name: String
        var title: String
        var cost: Double
        var procedureCode: String
        var locale: String
        var archived: Bool
        var encounterID: String
        var status: ClaimTierStatus

        init(code: String, name: String, title: String, cost: Double, procedureCode: String, locale: String, archived: Bool, encounterID: String, status: ClaimTierStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.cost = cost
            self.procedureCode = procedureCode
            self.locale = locale
            self.archived = archived
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ClaimTierStatus.completed
            case .inProgress:
                return next == ClaimTierStatus.completed || next == ClaimTierStatus.cancelled
            case .completed:
                return next == ClaimTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> ClaimTier {
            return ClaimTier(
                code: code,
                name: name,
                title: title,
                cost: cost,
                procedureCode: procedureCode,
                locale: locale,
                archived: archived,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a claim tier in status planned.
    static func newClaimTier(_ code: String, name: String) -> ClaimTier {
        return ClaimTier(
            code: code,
            name: name,
            title: "",
            cost: 0.0,
            procedureCode: "",
            locale: "",
            archived: false,
            encounterID: "",
            status: ClaimTierStatus.planned
        )
    }
}
