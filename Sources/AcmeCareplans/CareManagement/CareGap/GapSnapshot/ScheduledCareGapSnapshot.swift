import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled care gap snapshot is in its life cycle.
    enum ScheduledCareGapSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled care gap snapshot. Its code is unique within a tenant.
    final class ScheduledCareGapSnapshot {
        var code: String
        var title: String
        var floorValue: Double
        var country: String
        var approved: Bool
        var status: ScheduledCareGapSnapshotStatus

        init(code: String, title: String, floorValue: Double, country: String, approved: Bool, status: ScheduledCareGapSnapshotStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.country = country
            self.approved = approved
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

        func canMoveTo(_ next: ScheduledCareGapSnapshotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ScheduledCareGapSnapshotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareGapSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care gap snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> ScheduledCareGapSnapshot {
            return ScheduledCareGapSnapshot(
                code: code,
                title: title,
                floorValue: floorValue,
                country: country,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a scheduled care gap snapshot in status created.
    static func newScheduledCareGapSnapshot(_ code: String, title: String) -> ScheduledCareGapSnapshot {
        return ScheduledCareGapSnapshot(
            code: code,
            title: title,
            floorValue: 0.0,
            country: "",
            approved: false,
            status: ScheduledCareGapSnapshotStatus.created
        )
    }
}
