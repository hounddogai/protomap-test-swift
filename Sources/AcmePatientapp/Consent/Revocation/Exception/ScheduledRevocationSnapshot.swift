import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled revocation snapshot is in its life cycle.
    enum ScheduledRevocationSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled revocation snapshot. Its code is unique within a tenant.
    final class ScheduledRevocationSnapshot {
        var code: String
        var name: String
        var margin: Double
        var capacity: Int
        var sequence: Int
        var acuity: Int
        var specialty: String
        var batchSize: Int
        var rate: Double
        var version: Int
        var windowDays: Int
        var status: ScheduledRevocationSnapshotStatus

        init(code: String, name: String, margin: Double, capacity: Int, sequence: Int, acuity: Int, specialty: String, batchSize: Int, rate: Double, version: Int, windowDays: Int, status: ScheduledRevocationSnapshotStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.capacity = capacity
            self.sequence = sequence
            self.acuity = acuity
            self.specialty = specialty
            self.batchSize = batchSize
            self.rate = rate
            self.version = version
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ScheduledRevocationSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledRevocationSnapshotStatus.expired
            case .granted:
                return next == ScheduledRevocationSnapshotStatus.revoked
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

        func moveTo(_ next: ScheduledRevocationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled revocation snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("scheduled revocation snapshot") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(version) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRevocationSnapshot {
            return ScheduledRevocationSnapshot(
                code: code,
                name: name,
                margin: margin,
                capacity: capacity,
                sequence: sequence,
                acuity: acuity,
                specialty: specialty,
                batchSize: batchSize,
                rate: rate,
                version: version,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled revocation snapshot in status requested.
    static func newScheduledRevocationSnapshot(_ code: String, name: String) -> ScheduledRevocationSnapshot {
        return ScheduledRevocationSnapshot(
            code: code,
            name: name,
            margin: 0.0,
            capacity: 0,
            sequence: 0,
            acuity: 0,
            specialty: "",
            batchSize: 0,
            rate: 0.0,
            version: 0,
            windowDays: 0,
            status: ScheduledRevocationSnapshotStatus.requested
        )
    }
}
