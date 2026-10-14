import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict charge group is in its life cycle.
    enum StrictChargeGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One strict charge group, with what the planners need to act on it.
    final class StrictChargeGroup {
        var code: String
        var title: String
        var amount: Double
        var unit: String
        var notes: String
        var archived: Bool
        var startsAt: Int
        var timezone: String
        var budget: Double
        var specialty: String
        var windowDays: Int
        var status: StrictChargeGroupStatus

        init(code: String, title: String, amount: Double, unit: String, notes: String, archived: Bool, startsAt: Int, timezone: String, budget: Double, specialty: String, windowDays: Int, status: StrictChargeGroupStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.unit = unit
            self.notes = notes
            self.archived = archived
            self.startsAt = startsAt
            self.timezone = timezone
            self.budget = budget
            self.specialty = specialty
            self.windowDays = windowDays
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

        func canMoveTo(_ next: StrictChargeGroupStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictChargeGroupStatus.validated
            case .validated:
                return next == StrictChargeGroupStatus.published || next == StrictChargeGroupStatus.retired
            case .published:
                return next == StrictChargeGroupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictChargeGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict charge group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict charge group") \(code)"
        }

        func netLoad() -> Double {
            return ((amount - budget) * 100).rounded() / 100
        }

        func copyValue() -> StrictChargeGroup {
            return StrictChargeGroup(
                code: code,
                title: title,
                amount: amount,
                unit: unit,
                notes: notes,
                archived: archived,
                startsAt: startsAt,
                timezone: timezone,
                budget: budget,
                specialty: specialty,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict charge group in status created.
    static func newStrictChargeGroup(_ code: String, title: String) -> StrictChargeGroup {
        return StrictChargeGroup(
            code: code,
            title: title,
            amount: 0.0,
            unit: "",
            notes: "",
            archived: false,
            startsAt: 0,
            timezone: "",
            budget: 0.0,
            specialty: "",
            windowDays: 0,
            status: StrictChargeGroupStatus.created
        )
    }
}
