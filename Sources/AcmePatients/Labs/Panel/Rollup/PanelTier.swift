import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel tier is in its life cycle.
    enum PanelTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a panel tier and its current status.
    final class PanelTier {
        var code: String
        var label: String
        var name: String
        var retries: Int
        var revision: Int
        var status: PanelTierStatus

        init(code: String, label: String, name: String, retries: Int, revision: Int, status: PanelTierStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.retries = retries
            self.revision = revision
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

        func canMoveTo(_ next: PanelTierStatus) -> Bool {
            switch status {
            case .requested:
                return next == PanelTierStatus.revoked
            case .granted:
                return next == PanelTierStatus.revoked || next == PanelTierStatus.expired
            case .revoked:
                return next == PanelTierStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((Double(retries) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PanelTier {
            return PanelTier(
                code: code,
                label: label,
                name: name,
                retries: retries,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel tier in status requested.
    static func newPanelTier(_ code: String, label: String) -> PanelTier {
        return PanelTier(
            code: code,
            label: label,
            name: "",
            retries: 0,
            revision: 0,
            status: PanelTierStatus.requested
        )
    }
}
