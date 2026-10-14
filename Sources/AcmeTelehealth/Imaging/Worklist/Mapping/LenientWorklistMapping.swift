import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient worklist mapping is in its life cycle.
    enum LenientWorklistMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient worklist mapping as the worklist team keeps it.
    final class LenientWorklistMapping {
        var code: String
        var name: String
        var maximum: Double
        var margin: Double
        var active: Bool
        var retries: Int
        var status: LenientWorklistMappingStatus

        init(code: String, name: String, maximum: Double, margin: Double, active: Bool, retries: Int, status: LenientWorklistMappingStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.margin = margin
            self.active = active
            self.retries = retries
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

        func canMoveTo(_ next: LenientWorklistMappingStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientWorklistMappingStatus.granted || next == LenientWorklistMappingStatus.expired
            case .granted:
                return next == LenientWorklistMappingStatus.revoked
            case .revoked:
                return next == LenientWorklistMappingStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientWorklistMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient worklist mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return (Double(retries) * margin * 100).rounded() / 100
        }

        func copyValue() -> LenientWorklistMapping {
            return LenientWorklistMapping(
                code: code,
                name: name,
                maximum: maximum,
                margin: margin,
                active: active,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient worklist mapping in status requested.
    static func newLenientWorklistMapping(_ code: String, name: String) -> LenientWorklistMapping {
        return LenientWorklistMapping(
            code: code,
            name: name,
            maximum: 0.0,
            margin: 0.0,
            active: false,
            retries: 0,
            status: LenientWorklistMappingStatus.requested
        )
    }
}
