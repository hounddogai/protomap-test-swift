import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal inventory target is in its life cycle.
    enum SeasonalInventoryTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal inventory target as the inventory team keeps it.
    final class SeasonalInventoryTarget {
        var code: String
        var title: String
        var active: Bool
        var refills: Int
        var encounterID: String
        var createdAt: Int
        var maximum: Double
        var updatedAt: Int
        var phone: String
        var summary: String
        var bed: String
        var status: SeasonalInventoryTargetStatus

        init(code: String, title: String, active: Bool, refills: Int, encounterID: String, createdAt: Int, maximum: Double, updatedAt: Int, phone: String, summary: String, bed: String, status: SeasonalInventoryTargetStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.refills = refills
            self.encounterID = encounterID
            self.createdAt = createdAt
            self.maximum = maximum
            self.updatedAt = updatedAt
            self.phone = phone
            self.summary = summary
            self.bed = bed
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

        func canMoveTo(_ next: SeasonalInventoryTargetStatus) -> Bool {
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
                return next == SeasonalInventoryTargetStatus.revoked
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

        func moveTo(_ next: SeasonalInventoryTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal inventory target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveLoad() -> Double {
            return ((Double(refills) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalInventoryTarget {
            return SeasonalInventoryTarget(
                code: code,
                title: title,
                active: active,
                refills: refills,
                encounterID: encounterID,
                createdAt: createdAt,
                maximum: maximum,
                updatedAt: updatedAt,
                phone: phone,
                summary: summary,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal inventory target in status requested.
    static func newSeasonalInventoryTarget(_ code: String, title: String) -> SeasonalInventoryTarget {
        return SeasonalInventoryTarget(
            code: code,
            title: title,
            active: false,
            refills: 0,
            encounterID: "",
            createdAt: 0,
            maximum: 0.0,
            updatedAt: 0,
            phone: "",
            summary: "",
            bed: "",
            status: SeasonalInventoryTargetStatus.requested
        )
    }
}
