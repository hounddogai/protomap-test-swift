import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped handoff mapping is in its life cycle.
    enum CappedHandoffMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped handoff mapping, with what the planners need to act on it.
    final class CappedHandoffMapping {
        var code: String
        var name: String
        var ownerID: String
        var revision: Int
        var approved: Bool
        var weight: Double
        var expiresAt: Int
        var copay: Double
        var archived: Bool
        var endsAt: Int
        var status: CappedHandoffMappingStatus

        init(code: String, name: String, ownerID: String, revision: Int, approved: Bool, weight: Double, expiresAt: Int, copay: Double, archived: Bool, endsAt: Int, status: CappedHandoffMappingStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.revision = revision
            self.approved = approved
            self.weight = weight
            self.expiresAt = expiresAt
            self.copay = copay
            self.archived = archived
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedHandoffMappingStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedHandoffMappingStatus.resolved || next == CappedHandoffMappingStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedHandoffMappingStatus.reopened || next == CappedHandoffMappingStatus.archived
            case .reopened:
                return next == CappedHandoffMappingStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedHandoffMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped handoff mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("capped handoff mapping") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(endsAt) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedHandoffMapping {
            return CappedHandoffMapping(
                code: code,
                name: name,
                ownerID: ownerID,
                revision: revision,
                approved: approved,
                weight: weight,
                expiresAt: expiresAt,
                copay: copay,
                archived: archived,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped handoff mapping in status open.
    static func newCappedHandoffMapping(_ code: String, name: String) -> CappedHandoffMapping {
        return CappedHandoffMapping(
            code: code,
            name: name,
            ownerID: "",
            revision: 0,
            approved: false,
            weight: 0.0,
            expiresAt: 0,
            copay: 0.0,
            archived: false,
            endsAt: 0,
            status: CappedHandoffMappingStatus.`open`
        )
    }
}
