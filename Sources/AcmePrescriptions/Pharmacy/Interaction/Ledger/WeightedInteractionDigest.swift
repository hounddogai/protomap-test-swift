import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted interaction digest is in its life cycle.
    enum WeightedInteractionDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted interaction digest as the interaction team keeps it.
    final class WeightedInteractionDigest {
        var code: String
        var title: String
        var visible: Bool
        var name: String
        var budget: Double
        var updatedAt: Int
        var weight: Double
        var status: WeightedInteractionDigestStatus

        init(code: String, title: String, visible: Bool, name: String, budget: Double, updatedAt: Int, weight: Double, status: WeightedInteractionDigestStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.name = name
            self.budget = budget
            self.updatedAt = updatedAt
            self.weight = weight
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

        func canMoveTo(_ next: WeightedInteractionDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == WeightedInteractionDigestStatus.withdrawn
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

        func moveTo(_ next: WeightedInteractionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted interaction digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((weight - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedInteractionDigest {
            return WeightedInteractionDigest(
                code: code,
                title: title,
                visible: visible,
                name: name,
                budget: budget,
                updatedAt: updatedAt,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted interaction digest in status proposed.
    static func newWeightedInteractionDigest(_ code: String, title: String) -> WeightedInteractionDigest {
        return WeightedInteractionDigest(
            code: code,
            title: title,
            visible: false,
            name: "",
            budget: 0.0,
            updatedAt: 0,
            weight: 0.0,
            status: WeightedInteractionDigestStatus.proposed
        )
    }
}
