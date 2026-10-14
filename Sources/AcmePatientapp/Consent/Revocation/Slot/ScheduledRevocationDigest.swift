import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled revocation digest is in its life cycle.
    enum ScheduledRevocationDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled revocation digest as the revocation team keeps it.
    final class ScheduledRevocationDigest {
        var code: String
        var name: String
        var notes: String
        var startsAt: Int
        var unit: String
        var minimum: Double
        var clinicianID: String
        var status: ScheduledRevocationDigestStatus

        init(code: String, name: String, notes: String, startsAt: Int, unit: String, minimum: Double, clinicianID: String, status: ScheduledRevocationDigestStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.startsAt = startsAt
            self.unit = unit
            self.minimum = minimum
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: ScheduledRevocationDigestStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledRevocationDigestStatus.closed
            case .pending:
                return next == ScheduledRevocationDigestStatus.closed
            case .active:
                return next == ScheduledRevocationDigestStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ScheduledRevocationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled revocation digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedVolume() -> Double {
            return (Double(startsAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRevocationDigest {
            return ScheduledRevocationDigest(
                code: code,
                name: name,
                notes: notes,
                startsAt: startsAt,
                unit: unit,
                minimum: minimum,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled revocation digest in status draft.
    static func newScheduledRevocationDigest(_ code: String, name: String) -> ScheduledRevocationDigest {
        return ScheduledRevocationDigest(
            code: code,
            name: name,
            notes: "",
            startsAt: 0,
            unit: "",
            minimum: 0.0,
            clinicianID: "",
            status: ScheduledRevocationDigestStatus.draft
        )
    }
}
