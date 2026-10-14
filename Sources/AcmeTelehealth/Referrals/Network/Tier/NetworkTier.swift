import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network tier is in its life cycle.
    enum NetworkTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A network tier. Its code is unique within a tenant.
    final class NetworkTier {
        var code: String
        var title: String
        var payer: String
        var capacity: Int
        var weight: Double
        var budget: Double
        var endsAt: Int
        var ratio: Double
        var threshold: Double
        var floorValue: Double
        var acuity: Int
        var status: NetworkTierStatus

        init(code: String, title: String, payer: String, capacity: Int, weight: Double, budget: Double, endsAt: Int, ratio: Double, threshold: Double, floorValue: Double, acuity: Int, status: NetworkTierStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.capacity = capacity
            self.weight = weight
            self.budget = budget
            self.endsAt = endsAt
            self.ratio = ratio
            self.threshold = threshold
            self.floorValue = floorValue
            self.acuity = acuity
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

        func canMoveTo(_ next: NetworkTierStatus) -> Bool {
            switch status {
            case .planned:
                return next == NetworkTierStatus.scheduled || next == NetworkTierStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == NetworkTierStatus.completed
            case .completed:
                return next == NetworkTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return (floorValue * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> NetworkTier {
            return NetworkTier(
                code: code,
                title: title,
                payer: payer,
                capacity: capacity,
                weight: weight,
                budget: budget,
                endsAt: endsAt,
                ratio: ratio,
                threshold: threshold,
                floorValue: floorValue,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a network tier in status planned.
    static func newNetworkTier(_ code: String, title: String) -> NetworkTier {
        return NetworkTier(
            code: code,
            title: title,
            payer: "",
            capacity: 0,
            weight: 0.0,
            budget: 0.0,
            endsAt: 0,
            ratio: 0.0,
            threshold: 0.0,
            floorValue: 0.0,
            acuity: 0,
            status: NetworkTierStatus.planned
        )
    }
}
