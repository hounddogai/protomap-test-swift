import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional disclosure reservation is in its life cycle.
    enum RegionalDisclosureReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a regional disclosure reservation and its current status.
    final class RegionalDisclosureReservation {
        var code: String
        var title: String
        var copay: Double
        var facility: String
        var currency: String
        var refills: Int
        var minimum: Double
        var ownerID: String
        var weight: Double
        var status: RegionalDisclosureReservationStatus

        init(code: String, title: String, copay: Double, facility: String, currency: String, refills: Int, minimum: Double, ownerID: String, weight: Double, status: RegionalDisclosureReservationStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.facility = facility
            self.currency = currency
            self.refills = refills
            self.minimum = minimum
            self.ownerID = ownerID
            self.weight = weight
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

        func canMoveTo(_ next: RegionalDisclosureReservationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RegionalDisclosureReservationStatus.suspended || next == RegionalDisclosureReservationStatus.closed
            case .active:
                return next == RegionalDisclosureReservationStatus.closed
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

        func moveTo(_ next: RegionalDisclosureReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional disclosure reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((weight + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDisclosureReservation {
            return RegionalDisclosureReservation(
                code: code,
                title: title,
                copay: copay,
                facility: facility,
                currency: currency,
                refills: refills,
                minimum: minimum,
                ownerID: ownerID,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional disclosure reservation in status draft.
    static func newRegionalDisclosureReservation(_ code: String, title: String) -> RegionalDisclosureReservation {
        return RegionalDisclosureReservation(
            code: code,
            title: title,
            copay: 0.0,
            facility: "",
            currency: "",
            refills: 0,
            minimum: 0.0,
            ownerID: "",
            weight: 0.0,
            status: RegionalDisclosureReservationStatus.draft
        )
    }
}
