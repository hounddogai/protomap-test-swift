import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted transfer reservation is in its life cycle.
    enum WeightedTransferReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a weighted transfer reservation and its current status.
    final class WeightedTransferReservation {
        var code: String
        var title: String
        var budget: Double
        var limit: Int
        var priority: Int
        var locale: String
        var unit: String
        var durationMinutes: Int
        var status: WeightedTransferReservationStatus

        init(code: String, title: String, budget: Double, limit: Int, priority: Int, locale: String, unit: String, durationMinutes: Int, status: WeightedTransferReservationStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.limit = limit
            self.priority = priority
            self.locale = locale
            self.unit = unit
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: WeightedTransferReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedTransferReservationStatus.active || next == WeightedTransferReservationStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == WeightedTransferReservationStatus.suspended || next == WeightedTransferReservationStatus.closed
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

        func moveTo(_ next: WeightedTransferReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted transfer reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted transfer reservation") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(priority) - budget) * 100).rounded() / 100
        }

        func copyValue() -> WeightedTransferReservation {
            return WeightedTransferReservation(
                code: code,
                title: title,
                budget: budget,
                limit: limit,
                priority: priority,
                locale: locale,
                unit: unit,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted transfer reservation in status draft.
    static func newWeightedTransferReservation(_ code: String, title: String) -> WeightedTransferReservation {
        return WeightedTransferReservation(
            code: code,
            title: title,
            budget: 0.0,
            limit: 0,
            priority: 0,
            locale: "",
            unit: "",
            durationMinutes: 0,
            status: WeightedTransferReservationStatus.draft
        )
    }
}
