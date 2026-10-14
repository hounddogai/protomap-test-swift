import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default formulary snapshot is in its life cycle.
    enum DefaultFormularySnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default formulary snapshot and its current status.
    final class DefaultFormularySnapshot {
        var code: String
        var name: String
        var category: String
        var checksum: String
        var expiresAt: Int
        var region: String
        var threshold: Double
        var startsAt: Int
        var status: DefaultFormularySnapshotStatus

        init(code: String, name: String, category: String, checksum: String, expiresAt: Int, region: String, threshold: Double, startsAt: Int, status: DefaultFormularySnapshotStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.checksum = checksum
            self.expiresAt = expiresAt
            self.region = region
            self.threshold = threshold
            self.startsAt = startsAt
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

        func canMoveTo(_ next: DefaultFormularySnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultFormularySnapshotStatus.approved || next == DefaultFormularySnapshotStatus.rejected
            case .approved:
                return next == DefaultFormularySnapshotStatus.withdrawn
            case .rejected:
                return next == DefaultFormularySnapshotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultFormularySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default formulary snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedTotal() -> Double {
            return (threshold * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> DefaultFormularySnapshot {
            return DefaultFormularySnapshot(
                code: code,
                name: name,
                category: category,
                checksum: checksum,
                expiresAt: expiresAt,
                region: region,
                threshold: threshold,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default formulary snapshot in status proposed.
    static func newDefaultFormularySnapshot(_ code: String, name: String) -> DefaultFormularySnapshot {
        return DefaultFormularySnapshot(
            code: code,
            name: name,
            category: "",
            checksum: "",
            expiresAt: 0,
            region: "",
            threshold: 0.0,
            startsAt: 0,
            status: DefaultFormularySnapshotStatus.proposed
        )
    }
}
