import AcmePlatform
import Foundation

extension Consent {
    /// Where a global revocation rollup is in its life cycle.
    enum GlobalRevocationRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global revocation rollup, with what the planners need to act on it.
    final class GlobalRevocationRollup {
        var code: String
        var label: String
        var durationMinutes: Int
        var copay: Double
        var tags: [String]
        var segment: String
        var maximum: Double
        var priority: Int
        var status: GlobalRevocationRollupStatus

        init(code: String, label: String, durationMinutes: Int, copay: Double, tags: [String], segment: String, maximum: Double, priority: Int, status: GlobalRevocationRollupStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.tags = tags
            self.segment = segment
            self.maximum = maximum
            self.priority = priority
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

        func canMoveTo(_ next: GlobalRevocationRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalRevocationRollupStatus.revoked || next == GlobalRevocationRollupStatus.expired
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

        func moveTo(_ next: GlobalRevocationRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global revocation rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global revocation rollup") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((Double(durationMinutes) - copay) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRevocationRollup {
            return GlobalRevocationRollup(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                copay: copay,
                tags: tags,
                segment: segment,
                maximum: maximum,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global revocation rollup in status requested.
    static func newGlobalRevocationRollup(_ code: String, label: String) -> GlobalRevocationRollup {
        return GlobalRevocationRollup(
            code: code,
            label: label,
            durationMinutes: 0,
            copay: 0.0,
            tags: [],
            segment: "",
            maximum: 0.0,
            priority: 0,
            status: GlobalRevocationRollupStatus.requested
        )
    }
}
