import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted care protocol policy is in its life cycle.
    enum WeightedCareProtocolPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A weighted care protocol policy. Its code is unique within a tenant.
    final class WeightedCareProtocolPolicy {
        var code: String
        var name: String
        var graceDays: Int
        var country: String
        var visible: Bool
        var sequence: Int
        var rate: Double
        var createdAt: Int
        var visitMinutes: Int
        var updatedAt: Int
        var status: WeightedCareProtocolPolicyStatus

        init(code: String, name: String, graceDays: Int, country: String, visible: Bool, sequence: Int, rate: Double, createdAt: Int, visitMinutes: Int, updatedAt: Int, status: WeightedCareProtocolPolicyStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.country = country
            self.visible = visible
            self.sequence = sequence
            self.rate = rate
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: WeightedCareProtocolPolicyStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == WeightedCareProtocolPolicyStatus.inProgress
            case .inProgress:
                return next == WeightedCareProtocolPolicyStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: WeightedCareProtocolPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted care protocol policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedValue() -> Double {
            return (Double(createdAt) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCareProtocolPolicy {
            return WeightedCareProtocolPolicy(
                code: code,
                name: name,
                graceDays: graceDays,
                country: country,
                visible: visible,
                sequence: sequence,
                rate: rate,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted care protocol policy in status planned.
    static func newWeightedCareProtocolPolicy(_ code: String, name: String) -> WeightedCareProtocolPolicy {
        return WeightedCareProtocolPolicy(
            code: code,
            name: name,
            graceDays: 0,
            country: "",
            visible: false,
            sequence: 0,
            rate: 0.0,
            createdAt: 0,
            visitMinutes: 0,
            updatedAt: 0,
            status: WeightedCareProtocolPolicyStatus.planned
        )
    }
}
