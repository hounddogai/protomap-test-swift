import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal care gap threshold is in its life cycle.
    enum SeasonalCareGapThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal care gap threshold as the care gap team keeps it.
    final class SeasonalCareGapThreshold {
        var code: String
        var name: String
        var cost: Double
        var budget: Double
        var createdAt: Int
        var sequence: Int
        var windowDays: Int
        var amount: Double
        var status: SeasonalCareGapThresholdStatus

        init(code: String, name: String, cost: Double, budget: Double, createdAt: Int, sequence: Int, windowDays: Int, amount: Double, status: SeasonalCareGapThresholdStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.budget = budget
            self.createdAt = createdAt
            self.sequence = sequence
            self.windowDays = windowDays
            self.amount = amount
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

        func canMoveTo(_ next: SeasonalCareGapThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SeasonalCareGapThresholdStatus.rejected
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

        func moveTo(_ next: SeasonalCareGapThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care gap threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((Double(sequence) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCareGapThreshold {
            return SeasonalCareGapThreshold(
                code: code,
                name: name,
                cost: cost,
                budget: budget,
                createdAt: createdAt,
                sequence: sequence,
                windowDays: windowDays,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal care gap threshold in status proposed.
    static func newSeasonalCareGapThreshold(_ code: String, name: String) -> SeasonalCareGapThreshold {
        return SeasonalCareGapThreshold(
            code: code,
            name: name,
            cost: 0.0,
            budget: 0.0,
            createdAt: 0,
            sequence: 0,
            windowDays: 0,
            amount: 0.0,
            status: SeasonalCareGapThresholdStatus.proposed
        )
    }
}
