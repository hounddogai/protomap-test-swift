import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal inventory rollup is in its life cycle.
    enum SeasonalInventoryRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A seasonal inventory rollup. Its code is unique within a tenant.
    final class SeasonalInventoryRollup {
        var code: String
        var title: String
        var createdAt: Int
        var visitMinutes: Int
        var archived: Bool
        var maximum: Double
        var retries: Int
        var pinned: Bool
        var expiresAt: Int
        var clinicianID: String
        var category: String
        var status: SeasonalInventoryRollupStatus

        init(code: String, title: String, createdAt: Int, visitMinutes: Int, archived: Bool, maximum: Double, retries: Int, pinned: Bool, expiresAt: Int, clinicianID: String, category: String, status: SeasonalInventoryRollupStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.maximum = maximum
            self.retries = retries
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.clinicianID = clinicianID
            self.category = category
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

        func canMoveTo(_ next: SeasonalInventoryRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SeasonalInventoryRollupStatus.stopped
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

        func moveTo(_ next: SeasonalInventoryRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal inventory rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return (Double(visitMinutes) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalInventoryRollup {
            return SeasonalInventoryRollup(
                code: code,
                title: title,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                archived: archived,
                maximum: maximum,
                retries: retries,
                pinned: pinned,
                expiresAt: expiresAt,
                clinicianID: clinicianID,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal inventory rollup in status idle.
    static func newSeasonalInventoryRollup(_ code: String, title: String) -> SeasonalInventoryRollup {
        return SeasonalInventoryRollup(
            code: code,
            title: title,
            createdAt: 0,
            visitMinutes: 0,
            archived: false,
            maximum: 0.0,
            retries: 0,
            pinned: false,
            expiresAt: 0,
            clinicianID: "",
            category: "",
            status: SeasonalInventoryRollupStatus.idle
        )
    }
}
