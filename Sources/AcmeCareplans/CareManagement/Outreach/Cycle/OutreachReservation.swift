import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach reservation is in its life cycle.
    enum OutreachReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A outreach reservation. Its code is unique within a tenant.
    final class OutreachReservation {
        var code: String
        var label: String
        var notes: String
        var active: Bool
        var expiresAt: Int
        var externalRef: String
        var payer: String
        var reviewer: String
        var startsAt: Int
        var visitMinutes: Int
        var status: OutreachReservationStatus

        init(code: String, label: String, notes: String, active: Bool, expiresAt: Int, externalRef: String, payer: String, reviewer: String, startsAt: Int, visitMinutes: Int, status: OutreachReservationStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.active = active
            self.expiresAt = expiresAt
            self.externalRef = externalRef
            self.payer = payer
            self.reviewer = reviewer
            self.startsAt = startsAt
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: OutreachReservationStatus) -> Bool {
            switch status {
            case .created:
                return next == OutreachReservationStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: OutreachReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveValue() -> Double {
            return ((Double(expiresAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachReservation {
            return OutreachReservation(
                code: code,
                label: label,
                notes: notes,
                active: active,
                expiresAt: expiresAt,
                externalRef: externalRef,
                payer: payer,
                reviewer: reviewer,
                startsAt: startsAt,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a outreach reservation in status created.
    static func newOutreachReservation(_ code: String, label: String) -> OutreachReservation {
        return OutreachReservation(
            code: code,
            label: label,
            notes: "",
            active: false,
            expiresAt: 0,
            externalRef: "",
            payer: "",
            reviewer: "",
            startsAt: 0,
            visitMinutes: 0,
            status: OutreachReservationStatus.created
        )
    }
}
