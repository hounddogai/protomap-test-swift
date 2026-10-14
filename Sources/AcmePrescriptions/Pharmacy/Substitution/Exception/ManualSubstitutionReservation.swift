import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual substitution reservation is in its life cycle.
    enum ManualSubstitutionReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a manual substitution reservation and its current status.
    final class ManualSubstitutionReservation {
        var code: String
        var label: String
        var acuity: Int
        var name: String
        var notes: String
        var pinned: Bool
        var quantity: Int
        var startsAt: Int
        var locale: String
        var unit: String
        var status: ManualSubstitutionReservationStatus

        init(code: String, label: String, acuity: Int, name: String, notes: String, pinned: Bool, quantity: Int, startsAt: Int, locale: String, unit: String, status: ManualSubstitutionReservationStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.name = name
            self.notes = notes
            self.pinned = pinned
            self.quantity = quantity
            self.startsAt = startsAt
            self.locale = locale
            self.unit = unit
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

        func canMoveTo(_ next: ManualSubstitutionReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualSubstitutionReservationStatus.pending || next == ManualSubstitutionReservationStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ManualSubstitutionReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualSubstitutionReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual substitution reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((Double(acuity) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualSubstitutionReservation {
            return ManualSubstitutionReservation(
                code: code,
                label: label,
                acuity: acuity,
                name: name,
                notes: notes,
                pinned: pinned,
                quantity: quantity,
                startsAt: startsAt,
                locale: locale,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual substitution reservation in status draft.
    static func newManualSubstitutionReservation(_ code: String, label: String) -> ManualSubstitutionReservation {
        return ManualSubstitutionReservation(
            code: code,
            label: label,
            acuity: 0,
            name: "",
            notes: "",
            pinned: false,
            quantity: 0,
            startsAt: 0,
            locale: "",
            unit: "",
            status: ManualSubstitutionReservationStatus.draft
        )
    }
}
