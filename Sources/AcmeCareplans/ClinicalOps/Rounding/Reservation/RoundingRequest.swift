import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding request is in its life cycle.
    enum RoundingRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rounding request, with what the planners need to act on it.
    final class RoundingRequest {
        var code: String
        var label: String
        var quantity: Int
        var amount: Double
        var minimum: Double
        var createdAt: Int
        var visitMinutes: Int
        var status: RoundingRequestStatus

        init(code: String, label: String, quantity: Int, amount: Double, minimum: Double, createdAt: Int, visitMinutes: Int, status: RoundingRequestStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.amount = amount
            self.minimum = minimum
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: RoundingRequestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RoundingRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return ((minimum + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingRequest {
            return RoundingRequest(
                code: code,
                label: label,
                quantity: quantity,
                amount: amount,
                minimum: minimum,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rounding request in status created.
    static func newRoundingRequest(_ code: String, label: String) -> RoundingRequest {
        return RoundingRequest(
            code: code,
            label: label,
            quantity: 0,
            amount: 0.0,
            minimum: 0.0,
            createdAt: 0,
            visitMinutes: 0,
            status: RoundingRequestStatus.created
        )
    }
}
