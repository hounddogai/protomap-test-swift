import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy order set reservation is in its life cycle.
    enum LegacyOrderSetReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy order set reservation as the order set team keeps it.
    final class LegacyOrderSetReservation {
        var code: String
        var label: String
        var externalRef: String
        var region: String
        var contactEmail: String
        var quantity: Int
        var status: LegacyOrderSetReservationStatus

        init(code: String, label: String, externalRef: String, region: String, contactEmail: String, quantity: Int, status: LegacyOrderSetReservationStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.region = region
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyOrderSetReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyOrderSetReservationStatus.reopened || next == LegacyOrderSetReservationStatus.archived
            case .reopened:
                return next == LegacyOrderSetReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyOrderSetReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy order set reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> LegacyOrderSetReservation {
            return LegacyOrderSetReservation(
                code: code,
                label: label,
                externalRef: externalRef,
                region: region,
                contactEmail: contactEmail,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy order set reservation in status open.
    static func newLegacyOrderSetReservation(_ code: String, label: String) -> LegacyOrderSetReservation {
        return LegacyOrderSetReservation(
            code: code,
            label: label,
            externalRef: "",
            region: "",
            contactEmail: "",
            quantity: 0,
            status: LegacyOrderSetReservationStatus.`open`
        )
    }
}
