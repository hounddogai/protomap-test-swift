import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered skill mix reservation is in its life cycle.
    enum TieredSkillMixReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered skill mix reservation. Its code is unique within a tenant.
    final class TieredSkillMixReservation {
        var code: String
        var title: String
        var attempts: Int
        var visible: Bool
        var name: String
        var contactEmail: String
        var diagnosisCode: String
        var graceDays: Int
        var tags: [String]
        var ceiling: Double
        var status: TieredSkillMixReservationStatus

        init(code: String, title: String, attempts: Int, visible: Bool, name: String, contactEmail: String, diagnosisCode: String, graceDays: Int, tags: [String], ceiling: Double, status: TieredSkillMixReservationStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.visible = visible
            self.name = name
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
            self.tags = tags
            self.ceiling = ceiling
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

        func canMoveTo(_ next: TieredSkillMixReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredSkillMixReservationStatus.revoked
            case .granted:
                return next == TieredSkillMixReservationStatus.revoked || next == TieredSkillMixReservationStatus.expired
            case .revoked:
                return next == TieredSkillMixReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredSkillMixReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered skill mix reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((Double(graceDays) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> TieredSkillMixReservation {
            return TieredSkillMixReservation(
                code: code,
                title: title,
                attempts: attempts,
                visible: visible,
                name: name,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                graceDays: graceDays,
                tags: tags,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered skill mix reservation in status requested.
    static func newTieredSkillMixReservation(_ code: String, title: String) -> TieredSkillMixReservation {
        return TieredSkillMixReservation(
            code: code,
            title: title,
            attempts: 0,
            visible: false,
            name: "",
            contactEmail: "",
            diagnosisCode: "",
            graceDays: 0,
            tags: [],
            ceiling: 0.0,
            status: TieredSkillMixReservationStatus.requested
        )
    }
}
