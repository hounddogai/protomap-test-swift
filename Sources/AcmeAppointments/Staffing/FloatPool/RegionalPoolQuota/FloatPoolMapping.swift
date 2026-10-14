import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool mapping is in its life cycle.
    enum FloatPoolMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One float pool mapping, with what the planners need to act on it.
    final class FloatPoolMapping {
        var code: String
        var title: String
        var expiresAt: Int
        var tags: [String]
        var maximum: Double
        var retries: Int
        var status: FloatPoolMappingStatus

        init(code: String, title: String, expiresAt: Int, tags: [String], maximum: Double, retries: Int, status: FloatPoolMappingStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.tags = tags
            self.maximum = maximum
            self.retries = retries
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

        func canMoveTo(_ next: FloatPoolMappingStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FloatPoolMappingStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FloatPoolMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((Double(expiresAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolMapping {
            return FloatPoolMapping(
                code: code,
                title: title,
                expiresAt: expiresAt,
                tags: tags,
                maximum: maximum,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a float pool mapping in status proposed.
    static func newFloatPoolMapping(_ code: String, title: String) -> FloatPoolMapping {
        return FloatPoolMapping(
            code: code,
            title: title,
            expiresAt: 0,
            tags: [],
            maximum: 0.0,
            retries: 0,
            status: FloatPoolMappingStatus.proposed
        )
    }
}
