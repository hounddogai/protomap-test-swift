import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending formulary reservation is in its life cycle.
    enum PendingFormularyReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending formulary reservation, with what the planners need to act on it.
    final class PendingFormularyReservation {
        var code: String
        var name: String
        var unit: String
        var channel: String
        var budget: Double
        var durationMinutes: Int
        var reviewer: String
        var tags: [String]
        var score: Double
        var phone: String
        var status: PendingFormularyReservationStatus

        init(code: String, name: String, unit: String, channel: String, budget: Double, durationMinutes: Int, reviewer: String, tags: [String], score: Double, phone: String, status: PendingFormularyReservationStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.channel = channel
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.reviewer = reviewer
            self.tags = tags
            self.score = score
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingFormularyReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingFormularyReservationStatus.rejected || next == PendingFormularyReservationStatus.withdrawn
            case .approved:
                return next == PendingFormularyReservationStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PendingFormularyReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending formulary reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((score + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingFormularyReservation {
            return PendingFormularyReservation(
                code: code,
                name: name,
                unit: unit,
                channel: channel,
                budget: budget,
                durationMinutes: durationMinutes,
                reviewer: reviewer,
                tags: tags,
                score: score,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending formulary reservation in status proposed.
    static func newPendingFormularyReservation(_ code: String, name: String) -> PendingFormularyReservation {
        return PendingFormularyReservation(
            code: code,
            name: name,
            unit: "",
            channel: "",
            budget: 0.0,
            durationMinutes: 0,
            reviewer: "",
            tags: [],
            score: 0.0,
            phone: "",
            status: PendingFormularyReservationStatus.proposed
        )
    }
}
