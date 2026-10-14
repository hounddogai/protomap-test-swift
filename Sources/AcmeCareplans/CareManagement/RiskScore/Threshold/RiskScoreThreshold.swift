import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score threshold is in its life cycle.
    enum RiskScoreThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A risk score threshold. Its code is unique within a tenant.
    final class RiskScoreThreshold {
        var code: String
        var name: String
        var budget: Double
        var capacity: Int
        var margin: Double
        var windowDays: Int
        var quantity: Int
        var durationMinutes: Int
        var archived: Bool
        var status: RiskScoreThresholdStatus

        init(code: String, name: String, budget: Double, capacity: Int, margin: Double, windowDays: Int, quantity: Int, durationMinutes: Int, archived: Bool, status: RiskScoreThresholdStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.capacity = capacity
            self.margin = margin
            self.windowDays = windowDays
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreThresholdStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RiskScoreThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return ((margin + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreThreshold {
            return RiskScoreThreshold(
                code: code,
                name: name,
                budget: budget,
                capacity: capacity,
                margin: margin,
                windowDays: windowDays,
                quantity: quantity,
                durationMinutes: durationMinutes,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a risk score threshold in status requested.
    static func newRiskScoreThreshold(_ code: String, name: String) -> RiskScoreThreshold {
        return RiskScoreThreshold(
            code: code,
            name: name,
            budget: 0.0,
            capacity: 0,
            margin: 0.0,
            windowDays: 0,
            quantity: 0,
            durationMinutes: 0,
            archived: false,
            status: RiskScoreThresholdStatus.requested
        )
    }
}
