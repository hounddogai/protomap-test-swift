import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen cycle is in its life cycle.
    enum SpecimenCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One specimen cycle, with what the planners need to act on it.
    final class SpecimenCycle {
        var code: String
        var name: String
        var ratio: Double
        var country: String
        var active: Bool
        var score: Double
        var currency: String
        var amount: Double
        var margin: Double
        var updatedAt: Int
        var durationMinutes: Int
        var status: SpecimenCycleStatus

        init(code: String, name: String, ratio: Double, country: String, active: Bool, score: Double, currency: String, amount: Double, margin: Double, updatedAt: Int, durationMinutes: Int, status: SpecimenCycleStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.country = country
            self.active = active
            self.score = score
            self.currency = currency
            self.amount = amount
            self.margin = margin
            self.updatedAt = updatedAt
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: SpecimenCycleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SpecimenCycleStatus.published || next == SpecimenCycleStatus.retired
            case .published:
                return next == SpecimenCycleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return ((Double(durationMinutes) + amount) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenCycle {
            return SpecimenCycle(
                code: code,
                name: name,
                ratio: ratio,
                country: country,
                active: active,
                score: score,
                currency: currency,
                amount: amount,
                margin: margin,
                updatedAt: updatedAt,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a specimen cycle in status created.
    static func newSpecimenCycle(_ code: String, name: String) -> SpecimenCycle {
        return SpecimenCycle(
            code: code,
            name: name,
            ratio: 0.0,
            country: "",
            active: false,
            score: 0.0,
            currency: "",
            amount: 0.0,
            margin: 0.0,
            updatedAt: 0,
            durationMinutes: 0,
            status: SpecimenCycleStatus.created
        )
    }
}
