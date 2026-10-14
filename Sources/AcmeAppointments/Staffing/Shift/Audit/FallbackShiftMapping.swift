import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback shift mapping is in its life cycle.
    enum FallbackShiftMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback shift mapping. Its code is unique within a tenant.
    final class FallbackShiftMapping {
        var code: String
        var name: String
        var timezone: String
        var endsAt: Int
        var expiresAt: Int
        var status: FallbackShiftMappingStatus

        init(code: String, name: String, timezone: String, endsAt: Int, expiresAt: Int, status: FallbackShiftMappingStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.endsAt = endsAt
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: FallbackShiftMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackShiftMappingStatus.warming || next == FallbackShiftMappingStatus.stopped
            case .warming:
                return next == FallbackShiftMappingStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: FallbackShiftMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback shift mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback shift mapping") \(code)"
        }

        func netVolume() -> Double {
            return (Double(endsAt) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> FallbackShiftMapping {
            return FallbackShiftMapping(
                code: code,
                name: name,
                timezone: timezone,
                endsAt: endsAt,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback shift mapping in status idle.
    static func newFallbackShiftMapping(_ code: String, name: String) -> FallbackShiftMapping {
        return FallbackShiftMapping(
            code: code,
            name: name,
            timezone: "",
            endsAt: 0,
            expiresAt: 0,
            status: FallbackShiftMappingStatus.idle
        )
    }
}
