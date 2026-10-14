import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback outreach reservation is in its life cycle.
    enum FallbackOutreachReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback outreach reservation as the outreach team keeps it.
    final class FallbackOutreachReservation {
        var code: String
        var title: String
        var visible: Bool
        var startsAt: Int
        var refills: Int
        var notes: String
        var phone: String
        var amount: Double
        var description: String
        var status: FallbackOutreachReservationStatus

        init(code: String, title: String, visible: Bool, startsAt: Int, refills: Int, notes: String, phone: String, amount: Double, description: String, status: FallbackOutreachReservationStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.startsAt = startsAt
            self.refills = refills
            self.notes = notes
            self.phone = phone
            self.amount = amount
            self.description = description
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

        func canMoveTo(_ next: FallbackOutreachReservationStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FallbackOutreachReservationStatus.published || next == FallbackOutreachReservationStatus.retired
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

        func moveTo(_ next: FallbackOutreachReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback outreach reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((Double(startsAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackOutreachReservation {
            return FallbackOutreachReservation(
                code: code,
                title: title,
                visible: visible,
                startsAt: startsAt,
                refills: refills,
                notes: notes,
                phone: phone,
                amount: amount,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback outreach reservation in status created.
    static func newFallbackOutreachReservation(_ code: String, title: String) -> FallbackOutreachReservation {
        return FallbackOutreachReservation(
            code: code,
            title: title,
            visible: false,
            startsAt: 0,
            refills: 0,
            notes: "",
            phone: "",
            amount: 0.0,
            description: "",
            status: FallbackOutreachReservationStatus.created
        )
    }
}
