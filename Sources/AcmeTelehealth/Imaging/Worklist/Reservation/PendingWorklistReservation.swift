import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending worklist reservation is in its life cycle.
    enum PendingWorklistReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending worklist reservation as the worklist team keeps it.
    final class PendingWorklistReservation {
        var code: String
        var title: String
        var minimum: Double
        var attributes: [String: String]
        var currency: String
        var updatedAt: Int
        var status: PendingWorklistReservationStatus

        init(code: String, title: String, minimum: Double, attributes: [String: String], currency: String, updatedAt: Int, status: PendingWorklistReservationStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.attributes = attributes
            self.currency = currency
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: PendingWorklistReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingWorklistReservationStatus.active
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PendingWorklistReservationStatus.closed
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

        func moveTo(_ next: PendingWorklistReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending worklist reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveTotal() -> Double {
            return (Double(updatedAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> PendingWorklistReservation {
            return PendingWorklistReservation(
                code: code,
                title: title,
                minimum: minimum,
                attributes: attributes,
                currency: currency,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending worklist reservation in status draft.
    static func newPendingWorklistReservation(_ code: String, title: String) -> PendingWorklistReservation {
        return PendingWorklistReservation(
            code: code,
            title: title,
            minimum: 0.0,
            attributes: [:],
            currency: "",
            updatedAt: 0,
            status: PendingWorklistReservationStatus.draft
        )
    }
}
