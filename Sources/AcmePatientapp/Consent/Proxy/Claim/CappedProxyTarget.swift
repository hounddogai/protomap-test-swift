import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped proxy target is in its life cycle.
    enum CappedProxyTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped proxy target. Its code is unique within a tenant.
    final class CappedProxyTarget {
        var code: String
        var name: String
        var tags: [String]
        var timezone: String
        var visible: Bool
        var dosageMg: Double
        var priority: Int
        var status: CappedProxyTargetStatus

        init(code: String, name: String, tags: [String], timezone: String, visible: Bool, dosageMg: Double, priority: Int, status: CappedProxyTargetStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.timezone = timezone
            self.visible = visible
            self.dosageMg = dosageMg
            self.priority = priority
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

        func canMoveTo(_ next: CappedProxyTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedProxyTargetStatus.published
            case .validated:
                return next == CappedProxyTargetStatus.retired
            case .published:
                return next == CappedProxyTargetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedProxyTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped proxy target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((dosageMg - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> CappedProxyTarget {
            return CappedProxyTarget(
                code: code,
                name: name,
                tags: tags,
                timezone: timezone,
                visible: visible,
                dosageMg: dosageMg,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped proxy target in status created.
    static func newCappedProxyTarget(_ code: String, name: String) -> CappedProxyTarget {
        return CappedProxyTarget(
            code: code,
            name: name,
            tags: [],
            timezone: "",
            visible: false,
            dosageMg: 0.0,
            priority: 0,
            status: CappedProxyTargetStatus.created
        )
    }
}
