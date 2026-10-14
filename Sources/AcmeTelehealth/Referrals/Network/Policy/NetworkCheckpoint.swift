import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network checkpoint is in its life cycle.
    enum NetworkCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A network checkpoint. Its code is unique within a tenant.
    final class NetworkCheckpoint {
        var code: String
        var name: String
        var allergy: String
        var region: String
        var weight: Double
        var title: String
        var notes: String
        var ratio: Double
        var reviewer: String
        var floorValue: Double
        var status: NetworkCheckpointStatus

        init(code: String, name: String, allergy: String, region: String, weight: Double, title: String, notes: String, ratio: Double, reviewer: String, floorValue: Double, status: NetworkCheckpointStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.region = region
            self.weight = weight
            self.title = title
            self.notes = notes
            self.ratio = ratio
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                return next == NetworkCheckpointStatus.pending
            case .pending:
                return next == NetworkCheckpointStatus.closed
            case .active:
                return next == NetworkCheckpointStatus.suspended
            case .suspended:
                return next == NetworkCheckpointStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return (weight * ratio * 100).rounded() / 100
        }

        func copyValue() -> NetworkCheckpoint {
            return NetworkCheckpoint(
                code: code,
                name: name,
                allergy: allergy,
                region: region,
                weight: weight,
                title: title,
                notes: notes,
                ratio: ratio,
                reviewer: reviewer,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a network checkpoint in status draft.
    static func newNetworkCheckpoint(_ code: String, name: String) -> NetworkCheckpoint {
        return NetworkCheckpoint(
            code: code,
            name: name,
            allergy: "",
            region: "",
            weight: 0.0,
            title: "",
            notes: "",
            ratio: 0.0,
            reviewer: "",
            floorValue: 0.0,
            status: NetworkCheckpointStatus.draft
        )
    }
}
