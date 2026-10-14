import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default priority audit is in its life cycle.
    enum DefaultPriorityAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default priority audit and its current status.
    final class DefaultPriorityAudit {
        var code: String
        var name: String
        var ceiling: Double
        var source: String
        var locale: String
        var margin: Double
        var version: Int
        var country: String
        var phone: String
        var status: DefaultPriorityAuditStatus

        init(code: String, name: String, ceiling: Double, source: String, locale: String, margin: Double, version: Int, country: String, phone: String, status: DefaultPriorityAuditStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.source = source
            self.locale = locale
            self.margin = margin
            self.version = version
            self.country = country
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultPriorityAuditStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultPriorityAuditStatus.inProgress
            case .scheduled:
                return next == DefaultPriorityAuditStatus.completed
            case .inProgress:
                return next == DefaultPriorityAuditStatus.cancelled
            case .completed:
                return next == DefaultPriorityAuditStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultPriorityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default priority audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((margin + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultPriorityAudit {
            return DefaultPriorityAudit(
                code: code,
                name: name,
                ceiling: ceiling,
                source: source,
                locale: locale,
                margin: margin,
                version: version,
                country: country,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default priority audit in status planned.
    static func newDefaultPriorityAudit(_ code: String, name: String) -> DefaultPriorityAudit {
        return DefaultPriorityAudit(
            code: code,
            name: name,
            ceiling: 0.0,
            source: "",
            locale: "",
            margin: 0.0,
            version: 0,
            country: "",
            phone: "",
            status: DefaultPriorityAuditStatus.planned
        )
    }
}
