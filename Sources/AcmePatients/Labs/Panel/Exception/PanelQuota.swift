import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel quota is in its life cycle.
    enum PanelQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A panel quota as the panel team keeps it.
    final class PanelQuota {
        var code: String
        var title: String
        var category: String
        var visitMinutes: Int
        var channel: String
        var label: String
        var status: PanelQuotaStatus

        init(code: String, title: String, category: String, visitMinutes: Int, channel: String, label: String, status: PanelQuotaStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.label = label
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

        func canMoveTo(_ next: PanelQuotaStatus) -> Bool {
            switch status {
            case .requested:
                return next == PanelQuotaStatus.granted
            case .granted:
                return next == PanelQuotaStatus.revoked || next == PanelQuotaStatus.expired
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

        func moveTo(_ next: PanelQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> PanelQuota {
            return PanelQuota(
                code: code,
                title: title,
                category: category,
                visitMinutes: visitMinutes,
                channel: channel,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a panel quota in status requested.
    static func newPanelQuota(_ code: String, title: String) -> PanelQuota {
        return PanelQuota(
            code: code,
            title: title,
            category: "",
            visitMinutes: 0,
            channel: "",
            label: "",
            status: PanelQuotaStatus.requested
        )
    }
}
