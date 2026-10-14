import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal care gap snapshot is in its life cycle.
    enum SeasonalCareGapSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal care gap snapshot. Its code is unique within a tenant.
    final class SeasonalCareGapSnapshot {
        var code: String
        var name: String
        var checksum: String
        var floorValue: Double
        var channel: String
        var tags: [String]
        var allergy: String
        var active: Bool
        var status: SeasonalCareGapSnapshotStatus

        init(code: String, name: String, checksum: String, floorValue: Double, channel: String, tags: [String], allergy: String, active: Bool, status: SeasonalCareGapSnapshotStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.floorValue = floorValue
            self.channel = channel
            self.tags = tags
            self.allergy = allergy
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalCareGapSnapshotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SeasonalCareGapSnapshotStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SeasonalCareGapSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care gap snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal care gap snapshot") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> SeasonalCareGapSnapshot {
            return SeasonalCareGapSnapshot(
                code: code,
                name: name,
                checksum: checksum,
                floorValue: floorValue,
                channel: channel,
                tags: tags,
                allergy: allergy,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a seasonal care gap snapshot in status created.
    static func newSeasonalCareGapSnapshot(_ code: String, name: String) -> SeasonalCareGapSnapshot {
        return SeasonalCareGapSnapshot(
            code: code,
            name: name,
            checksum: "",
            floorValue: 0.0,
            channel: "",
            tags: [],
            allergy: "",
            active: false,
            status: SeasonalCareGapSnapshotStatus.created
        )
    }
}
