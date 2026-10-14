import AcmePlatform
import Foundation

extension Labs {
    /// Where a default accession reservation is in its life cycle.
    enum DefaultAccessionReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default accession reservation and its current status.
    final class DefaultAccessionReservation {
        var code: String
        var title: String
        var phone: String
        var updatedAt: Int
        var attempts: Int
        var currency: String
        var budget: Double
        var threshold: Double
        var minimum: Double
        var maximum: Double
        var status: DefaultAccessionReservationStatus

        init(code: String, title: String, phone: String, updatedAt: Int, attempts: Int, currency: String, budget: Double, threshold: Double, minimum: Double, maximum: Double, status: DefaultAccessionReservationStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.currency = currency
            self.budget = budget
            self.threshold = threshold
            self.minimum = minimum
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultAccessionReservationStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultAccessionReservationStatus.ready || next == DefaultAccessionReservationStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultAccessionReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default accession reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return ((Double(updatedAt) + budget) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAccessionReservation {
            return DefaultAccessionReservation(
                code: code,
                title: title,
                phone: phone,
                updatedAt: updatedAt,
                attempts: attempts,
                currency: currency,
                budget: budget,
                threshold: threshold,
                minimum: minimum,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default accession reservation in status idle.
    static func newDefaultAccessionReservation(_ code: String, title: String) -> DefaultAccessionReservation {
        return DefaultAccessionReservation(
            code: code,
            title: title,
            phone: "",
            updatedAt: 0,
            attempts: 0,
            currency: "",
            budget: 0.0,
            threshold: 0.0,
            minimum: 0.0,
            maximum: 0.0,
            status: DefaultAccessionReservationStatus.idle
        )
    }
}
