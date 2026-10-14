import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read template is in its life cycle.
    enum ReadTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A read template. Its code is unique within a tenant.
    final class ReadTemplate {
        var code: String
        var label: String
        var locale: String
        var acuity: Int
        var windowDays: Int
        var approved: Bool
        var margin: Double
        var status: ReadTemplateStatus

        init(code: String, label: String, locale: String, acuity: Int, windowDays: Int, approved: Bool, margin: Double, status: ReadTemplateStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.acuity = acuity
            self.windowDays = windowDays
            self.approved = approved
            self.margin = margin
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

        func canMoveTo(_ next: ReadTemplateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ReadTemplateStatus.revoked || next == ReadTemplateStatus.expired
            case .revoked:
                return next == ReadTemplateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netTotal() -> Double {
            return ((margin + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ReadTemplate {
            return ReadTemplate(
                code: code,
                label: label,
                locale: locale,
                acuity: acuity,
                windowDays: windowDays,
                approved: approved,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a read template in status requested.
    static func newReadTemplate(_ code: String, label: String) -> ReadTemplate {
        return ReadTemplate(
            code: code,
            label: label,
            locale: "",
            acuity: 0,
            windowDays: 0,
            approved: false,
            margin: 0.0,
            status: ReadTemplateStatus.requested
        )
    }
}
