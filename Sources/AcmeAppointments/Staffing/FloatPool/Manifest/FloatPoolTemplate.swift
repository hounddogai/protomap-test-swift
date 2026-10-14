import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool template is in its life cycle.
    enum FloatPoolTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a float pool template and its current status.
    final class FloatPoolTemplate {
        var code: String
        var name: String
        var segment: String
        var label: String
        var version: Int
        var endsAt: Int
        var status: FloatPoolTemplateStatus

        init(code: String, name: String, segment: String, label: String, version: Int, endsAt: Int, status: FloatPoolTemplateStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.label = label
            self.version = version
            self.endsAt = endsAt
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

        func canMoveTo(_ next: FloatPoolTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FloatPoolTemplateStatus.rejected || next == FloatPoolTemplateStatus.withdrawn
            case .approved:
                return next == FloatPoolTemplateStatus.withdrawn
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

        func moveTo(_ next: FloatPoolTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return ((Double(endsAt) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolTemplate {
            return FloatPoolTemplate(
                code: code,
                name: name,
                segment: segment,
                label: label,
                version: version,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a float pool template in status proposed.
    static func newFloatPoolTemplate(_ code: String, name: String) -> FloatPoolTemplate {
        return FloatPoolTemplate(
            code: code,
            name: name,
            segment: "",
            label: "",
            version: 0,
            endsAt: 0,
            status: FloatPoolTemplateStatus.proposed
        )
    }
}
