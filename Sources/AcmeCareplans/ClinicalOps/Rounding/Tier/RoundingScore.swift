import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding score is in its life cycle.
    enum RoundingScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rounding score. Its code is unique within a tenant.
    final class RoundingScore {
        var code: String
        var label: String
        var graceDays: Int
        var region: String
        var minimum: Double
        var discount: Double
        var status: RoundingScoreStatus

        init(code: String, label: String, graceDays: Int, region: String, minimum: Double, discount: Double, status: RoundingScoreStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.region = region
            self.minimum = minimum
            self.discount = discount
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

        func canMoveTo(_ next: RoundingScoreStatus) -> Bool {
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
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RoundingScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return (Double(graceDays) * minimum * 100).rounded() / 100
        }

        func copyValue() -> RoundingScore {
            return RoundingScore(
                code: code,
                label: label,
                graceDays: graceDays,
                region: region,
                minimum: minimum,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rounding score in status proposed.
    static func newRoundingScore(_ code: String, label: String) -> RoundingScore {
        return RoundingScore(
            code: code,
            label: label,
            graceDays: 0,
            region: "",
            minimum: 0.0,
            discount: 0.0,
            status: RoundingScoreStatus.proposed
        )
    }
}
