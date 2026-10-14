import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered cleaning reservation is in its life cycle.
    enum TieredCleaningReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered cleaning reservation as the cleaning team keeps it.
    final class TieredCleaningReservation {
        var code: String
        var name: String
        var notes: String
        var country: String
        var active: Bool
        var createdAt: Int
        var channel: String
        var score: Double
        var amount: Double
        var pinned: Bool
        var status: TieredCleaningReservationStatus

        init(code: String, name: String, notes: String, country: String, active: Bool, createdAt: Int, channel: String, score: Double, amount: Double, pinned: Bool, status: TieredCleaningReservationStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.country = country
            self.active = active
            self.createdAt = createdAt
            self.channel = channel
            self.score = score
            self.amount = amount
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredCleaningReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == TieredCleaningReservationStatus.completed || next == TieredCleaningReservationStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == TieredCleaningReservationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCleaningReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered cleaning reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered cleaning reservation") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(createdAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> TieredCleaningReservation {
            return TieredCleaningReservation(
                code: code,
                name: name,
                notes: notes,
                country: country,
                active: active,
                createdAt: createdAt,
                channel: channel,
                score: score,
                amount: amount,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered cleaning reservation in status planned.
    static func newTieredCleaningReservation(_ code: String, name: String) -> TieredCleaningReservation {
        return TieredCleaningReservation(
            code: code,
            name: name,
            notes: "",
            country: "",
            active: false,
            createdAt: 0,
            channel: "",
            score: 0.0,
            amount: 0.0,
            pinned: false,
            status: TieredCleaningReservationStatus.planned
        )
    }
}
