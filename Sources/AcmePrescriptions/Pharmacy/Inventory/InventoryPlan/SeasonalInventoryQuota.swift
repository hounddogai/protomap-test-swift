import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal inventory quota is in its life cycle.
    enum SeasonalInventoryQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal inventory quota. Its code is unique within a tenant.
    final class SeasonalInventoryQuota {
        var code: String
        var label: String
        var version: Int
        var createdAt: Int
        var region: String
        var name: String
        var status: SeasonalInventoryQuotaStatus

        init(code: String, label: String, version: Int, createdAt: Int, region: String, name: String, status: SeasonalInventoryQuotaStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.createdAt = createdAt
            self.region = region
            self.name = name
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

        func canMoveTo(_ next: SeasonalInventoryQuotaStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalInventoryQuotaStatus.inProgress || next == SeasonalInventoryQuotaStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SeasonalInventoryQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal inventory quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("seasonal inventory quota") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(version) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalInventoryQuota {
            return SeasonalInventoryQuota(
                code: code,
                label: label,
                version: version,
                createdAt: createdAt,
                region: region,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a seasonal inventory quota in status planned.
    static func newSeasonalInventoryQuota(_ code: String, label: String) -> SeasonalInventoryQuota {
        return SeasonalInventoryQuota(
            code: code,
            label: label,
            version: 0,
            createdAt: 0,
            region: "",
            name: "",
            status: SeasonalInventoryQuotaStatus.planned
        )
    }
}
