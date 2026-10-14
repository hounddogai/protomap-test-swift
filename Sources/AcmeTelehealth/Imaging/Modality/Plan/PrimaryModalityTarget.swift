import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary modality target is in its life cycle.
    enum PrimaryModalityTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary modality target. Its code is unique within a tenant.
    final class PrimaryModalityTarget {
        var code: String
        var title: String
        var country: String
        var limit: Int
        var visitMinutes: Int
        var updatedAt: Int
        var encounterID: String
        var archived: Bool
        var status: PrimaryModalityTargetStatus

        init(code: String, title: String, country: String, limit: Int, visitMinutes: Int, updatedAt: Int, encounterID: String, archived: Bool, status: PrimaryModalityTargetStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.archived = archived
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

        func canMoveTo(_ next: PrimaryModalityTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PrimaryModalityTargetStatus.rejected || next == PrimaryModalityTargetStatus.withdrawn
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

        func moveTo(_ next: PrimaryModalityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary modality target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedValue() -> Double {
            return ((Double(visitMinutes) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryModalityTarget {
            return PrimaryModalityTarget(
                code: code,
                title: title,
                country: country,
                limit: limit,
                visitMinutes: visitMinutes,
                updatedAt: updatedAt,
                encounterID: encounterID,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary modality target in status proposed.
    static func newPrimaryModalityTarget(_ code: String, title: String) -> PrimaryModalityTarget {
        return PrimaryModalityTarget(
            code: code,
            title: title,
            country: "",
            limit: 0,
            visitMinutes: 0,
            updatedAt: 0,
            encounterID: "",
            archived: false,
            status: PrimaryModalityTargetStatus.proposed
        )
    }
}
