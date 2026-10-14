import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered care gap policy is in its life cycle.
    enum TieredCareGapPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered care gap policy as the care gap team keeps it.
    final class TieredCareGapPolicy {
        var code: String
        var name: String
        var version: Int
        var minimum: Double
        var description: String
        var status: TieredCareGapPolicyStatus

        init(code: String, name: String, version: Int, minimum: Double, description: String, status: TieredCareGapPolicyStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.minimum = minimum
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

        func canMoveTo(_ next: TieredCareGapPolicyStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == TieredCareGapPolicyStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TieredCareGapPolicyStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCareGapPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care gap policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(version) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareGapPolicy {
            return TieredCareGapPolicy(
                code: code,
                name: name,
                version: version,
                minimum: minimum,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered care gap policy in status idle.
    static func newTieredCareGapPolicy(_ code: String, name: String) -> TieredCareGapPolicy {
        return TieredCareGapPolicy(
            code: code,
            name: name,
            version: 0,
            minimum: 0.0,
            description: "",
            status: TieredCareGapPolicyStatus.idle
        )
    }
}
