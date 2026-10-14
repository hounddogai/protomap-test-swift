import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered priority reservation is in its life cycle.
    enum TieredPriorityReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a tiered priority reservation and its current status.
    final class TieredPriorityReservation {
        var code: String
        var title: String
        var priority: Int
        var retries: Int
        var attributes: [String: String]
        var encounterID: String
        var timezone: String
        var payer: String
        var status: TieredPriorityReservationStatus

        init(code: String, title: String, priority: Int, retries: Int, attributes: [String: String], encounterID: String, timezone: String, payer: String, status: TieredPriorityReservationStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.retries = retries
            self.attributes = attributes
            self.encounterID = encounterID
            self.timezone = timezone
            self.payer = payer
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

        func canMoveTo(_ next: TieredPriorityReservationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredPriorityReservationStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == TieredPriorityReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredPriorityReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered priority reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func projectedVolume() -> Double {
            return ((Double(retries) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> TieredPriorityReservation {
            return TieredPriorityReservation(
                code: code,
                title: title,
                priority: priority,
                retries: retries,
                attributes: attributes,
                encounterID: encounterID,
                timezone: timezone,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered priority reservation in status open.
    static func newTieredPriorityReservation(_ code: String, title: String) -> TieredPriorityReservation {
        return TieredPriorityReservation(
            code: code,
            title: title,
            priority: 0,
            retries: 0,
            attributes: [:],
            encounterID: "",
            timezone: "",
            payer: "",
            status: TieredPriorityReservationStatus.`open`
        )
    }
}
