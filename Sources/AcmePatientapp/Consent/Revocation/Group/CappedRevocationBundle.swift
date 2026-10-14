import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped revocation bundle is in its life cycle.
    enum CappedRevocationBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a capped revocation bundle and its current status.
    final class CappedRevocationBundle {
        var code: String
        var name: String
        var ceiling: Double
        var rate: Double
        var maximum: Double
        var weight: Double
        var acuity: Int
        var ratio: Double
        var status: CappedRevocationBundleStatus

        init(code: String, name: String, ceiling: Double, rate: Double, maximum: Double, weight: Double, acuity: Int, ratio: Double, status: CappedRevocationBundleStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.rate = rate
            self.maximum = maximum
            self.weight = weight
            self.acuity = acuity
            self.ratio = ratio
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

        func canMoveTo(_ next: CappedRevocationBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedRevocationBundleStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CappedRevocationBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRevocationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped revocation bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return ((ratio - weight) * 100).rounded() / 100
        }

        func copyValue() -> CappedRevocationBundle {
            return CappedRevocationBundle(
                code: code,
                name: name,
                ceiling: ceiling,
                rate: rate,
                maximum: maximum,
                weight: weight,
                acuity: acuity,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped revocation bundle in status proposed.
    static func newCappedRevocationBundle(_ code: String, name: String) -> CappedRevocationBundle {
        return CappedRevocationBundle(
            code: code,
            name: name,
            ceiling: 0.0,
            rate: 0.0,
            maximum: 0.0,
            weight: 0.0,
            acuity: 0,
            ratio: 0.0,
            status: CappedRevocationBundleStatus.proposed
        )
    }
}
