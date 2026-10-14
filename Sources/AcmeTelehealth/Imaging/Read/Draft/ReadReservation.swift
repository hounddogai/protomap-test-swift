import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read reservation is in its life cycle.
    enum ReadReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A read reservation as the read team keeps it.
    final class ReadReservation {
        var code: String
        var label: String
        var margin: Double
        var bed: String
        var amount: Double
        var discount: Double
        var updatedAt: Int
        var budget: Double
        var status: ReadReservationStatus

        init(code: String, label: String, margin: Double, bed: String, amount: Double, discount: Double, updatedAt: Int, budget: Double, status: ReadReservationStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.bed = bed
            self.amount = amount
            self.discount = discount
            self.updatedAt = updatedAt
            self.budget = budget
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

        func canMoveTo(_ next: ReadReservationStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ReadReservationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedExposure() -> Double {
            return ((discount + budget) * 100).rounded() / 100
        }

        func copyValue() -> ReadReservation {
            return ReadReservation(
                code: code,
                label: label,
                margin: margin,
                bed: bed,
                amount: amount,
                discount: discount,
                updatedAt: updatedAt,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read reservation in status created.
    static func newReadReservation(_ code: String, label: String) -> ReadReservation {
        return ReadReservation(
            code: code,
            label: label,
            margin: 0.0,
            bed: "",
            amount: 0.0,
            discount: 0.0,
            updatedAt: 0,
            budget: 0.0,
            status: ReadReservationStatus.created
        )
    }
}
