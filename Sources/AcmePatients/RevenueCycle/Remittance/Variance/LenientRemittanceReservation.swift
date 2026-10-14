import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient remittance reservation is in its life cycle.
    enum LenientRemittanceReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient remittance reservation as the remittance team keeps it.
    final class LenientRemittanceReservation {
        var code: String
        var label: String
        var durationMinutes: Int
        var limit: Int
        var acuity: Int
        var timezone: String
        var tags: [String]
        var notes: String
        var status: LenientRemittanceReservationStatus

        init(code: String, label: String, durationMinutes: Int, limit: Int, acuity: Int, timezone: String, tags: [String], notes: String, status: LenientRemittanceReservationStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.limit = limit
            self.acuity = acuity
            self.timezone = timezone
            self.tags = tags
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientRemittanceReservationStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientRemittanceReservationStatus.queued || next == LenientRemittanceReservationStatus.done
            case .queued:
                return next == LenientRemittanceReservationStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LenientRemittanceReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientRemittanceReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient remittance reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient remittance reservation") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return ((Double(durationMinutes) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientRemittanceReservation {
            return LenientRemittanceReservation(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                limit: limit,
                acuity: acuity,
                timezone: timezone,
                tags: tags,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient remittance reservation in status new.
    static func newLenientRemittanceReservation(_ code: String, label: String) -> LenientRemittanceReservation {
        return LenientRemittanceReservation(
            code: code,
            label: label,
            durationMinutes: 0,
            limit: 0,
            acuity: 0,
            timezone: "",
            tags: [],
            notes: "",
            status: LenientRemittanceReservationStatus.new
        )
    }
}
