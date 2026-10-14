import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default dispense manifest is in its life cycle.
    enum DefaultDispenseManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default dispense manifest as the dispense team keeps it.
    final class DefaultDispenseManifest {
        var code: String
        var title: String
        var timezone: String
        var ownerID: String
        var patientRef: String
        var retries: Int
        var limit: Int
        var ceiling: Double
        var ratio: Double
        var notes: String
        var endsAt: Int
        var status: DefaultDispenseManifestStatus

        init(code: String, title: String, timezone: String, ownerID: String, patientRef: String, retries: Int, limit: Int, ceiling: Double, ratio: Double, notes: String, endsAt: Int, status: DefaultDispenseManifestStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.ownerID = ownerID
            self.patientRef = patientRef
            self.retries = retries
            self.limit = limit
            self.ceiling = ceiling
            self.ratio = ratio
            self.notes = notes
            self.endsAt = endsAt
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

        func canMoveTo(_ next: DefaultDispenseManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultDispenseManifestStatus.withdrawn
            case .rejected:
                return next == DefaultDispenseManifestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultDispenseManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default dispense manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((ratio + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultDispenseManifest {
            return DefaultDispenseManifest(
                code: code,
                title: title,
                timezone: timezone,
                ownerID: ownerID,
                patientRef: patientRef,
                retries: retries,
                limit: limit,
                ceiling: ceiling,
                ratio: ratio,
                notes: notes,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default dispense manifest in status proposed.
    static func newDefaultDispenseManifest(_ code: String, title: String) -> DefaultDispenseManifest {
        return DefaultDispenseManifest(
            code: code,
            title: title,
            timezone: "",
            ownerID: "",
            patientRef: "",
            retries: 0,
            limit: 0,
            ceiling: 0.0,
            ratio: 0.0,
            notes: "",
            endsAt: 0,
            status: DefaultDispenseManifestStatus.proposed
        )
    }
}
