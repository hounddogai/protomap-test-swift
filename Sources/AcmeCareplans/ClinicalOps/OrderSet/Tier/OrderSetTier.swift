import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set tier is in its life cycle.
    enum OrderSetTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A order set tier as the order set team keeps it.
    final class OrderSetTier {
        var code: String
        var label: String
        var capacity: Int
        var score: Double
        var diagnosisCode: String
        var description: String
        var status: OrderSetTierStatus

        init(code: String, label: String, capacity: Int, score: Double, diagnosisCode: String, description: String, status: OrderSetTierStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.description = description
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

        func canMoveTo(_ next: OrderSetTierStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: OrderSetTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return ((score + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetTier {
            return OrderSetTier(
                code: code,
                label: label,
                capacity: capacity,
                score: score,
                diagnosisCode: diagnosisCode,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set tier in status idle.
    static func newOrderSetTier(_ code: String, label: String) -> OrderSetTier {
        return OrderSetTier(
            code: code,
            label: label,
            capacity: 0,
            score: 0.0,
            diagnosisCode: "",
            description: "",
            status: OrderSetTierStatus.idle
        )
    }
}
