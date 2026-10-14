import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal inventory notice is in its life cycle.
    enum SeasonalInventoryNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal inventory notice. Its code is unique within a tenant.
    final class SeasonalInventoryNotice {
        var code: String
        var title: String
        var region: String
        var version: Int
        var refills: Int
        var floorValue: Double
        var expiresAt: Int
        var limit: Int
        var bed: String
        var maximum: Double
        var status: SeasonalInventoryNoticeStatus

        init(code: String, title: String, region: String, version: Int, refills: Int, floorValue: Double, expiresAt: Int, limit: Int, bed: String, maximum: Double, status: SeasonalInventoryNoticeStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.version = version
            self.refills = refills
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.limit = limit
            self.bed = bed
            self.maximum = maximum
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

        func canMoveTo(_ next: SeasonalInventoryNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SeasonalInventoryNoticeStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalInventoryNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal inventory notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedVolume() -> Double {
            return (floorValue * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalInventoryNotice {
            return SeasonalInventoryNotice(
                code: code,
                title: title,
                region: region,
                version: version,
                refills: refills,
                floorValue: floorValue,
                expiresAt: expiresAt,
                limit: limit,
                bed: bed,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a seasonal inventory notice in status proposed.
    static func newSeasonalInventoryNotice(_ code: String, title: String) -> SeasonalInventoryNotice {
        return SeasonalInventoryNotice(
            code: code,
            title: title,
            region: "",
            version: 0,
            refills: 0,
            floorValue: 0.0,
            expiresAt: 0,
            limit: 0,
            bed: "",
            maximum: 0.0,
            status: SeasonalInventoryNoticeStatus.proposed
        )
    }
}
