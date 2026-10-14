import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling care protocol tier is in its life cycle.
    enum RollingCareProtocolTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling care protocol tier. Its code is unique within a tenant.
    final class RollingCareProtocolTier {
        var code: String
        var name: String
        var description: String
        var acuity: Int
        var currency: String
        var pinned: Bool
        var status: RollingCareProtocolTierStatus

        init(code: String, name: String, description: String, acuity: Int, currency: String, pinned: Bool, status: RollingCareProtocolTierStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.acuity = acuity
            self.currency = currency
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingCareProtocolTierStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingCareProtocolTierStatus.running || next == RollingCareProtocolTierStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingCareProtocolTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> RollingCareProtocolTier {
            return RollingCareProtocolTier(
                code: code,
                name: name,
                description: description,
                acuity: acuity,
                currency: currency,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling care protocol tier in status new.
    static func newRollingCareProtocolTier(_ code: String, name: String) -> RollingCareProtocolTier {
        return RollingCareProtocolTier(
            code: code,
            name: name,
            description: "",
            acuity: 0,
            currency: "",
            pinned: false,
            status: RollingCareProtocolTierStatus.new
        )
    }
}
