import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary worklist snapshot is in its life cycle.
    enum PrimaryWorklistSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary worklist snapshot, with what the planners need to act on it.
    final class PrimaryWorklistSnapshot {
        var code: String
        var title: String
        var procedureCode: String
        var maximum: Double
        var name: String
        var allergy: String
        var discount: Double
        var timezone: String
        var status: PrimaryWorklistSnapshotStatus

        init(code: String, title: String, procedureCode: String, maximum: Double, name: String, allergy: String, discount: Double, timezone: String, status: PrimaryWorklistSnapshotStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.name = name
            self.allergy = allergy
            self.discount = discount
            self.timezone = timezone
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

        func canMoveTo(_ next: PrimaryWorklistSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryWorklistSnapshotStatus.revoked
            case .granted:
                return next == PrimaryWorklistSnapshotStatus.revoked || next == PrimaryWorklistSnapshotStatus.expired
            case .revoked:
                return next == PrimaryWorklistSnapshotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryWorklistSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary worklist snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary worklist snapshot") \(code)"
        }

        func effectiveValue() -> Double {
            return ((maximum - discount) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryWorklistSnapshot {
            return PrimaryWorklistSnapshot(
                code: code,
                title: title,
                procedureCode: procedureCode,
                maximum: maximum,
                name: name,
                allergy: allergy,
                discount: discount,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary worklist snapshot in status requested.
    static func newPrimaryWorklistSnapshot(_ code: String, title: String) -> PrimaryWorklistSnapshot {
        return PrimaryWorklistSnapshot(
            code: code,
            title: title,
            procedureCode: "",
            maximum: 0.0,
            name: "",
            allergy: "",
            discount: 0.0,
            timezone: "",
            status: PrimaryWorklistSnapshotStatus.requested
        )
    }
}
