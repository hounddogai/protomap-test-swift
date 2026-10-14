import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive handoff digest is in its life cycle.
    enum AdaptiveHandoffDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive handoff digest, with what the planners need to act on it.
    final class AdaptiveHandoffDigest {
        var code: String
        var label: String
        var dosageMg: Double
        var title: String
        var updatedAt: Int
        var phone: String
        var bed: String
        var ownerID: String
        var status: AdaptiveHandoffDigestStatus

        init(code: String, label: String, dosageMg: Double, title: String, updatedAt: Int, phone: String, bed: String, ownerID: String, status: AdaptiveHandoffDigestStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.title = title
            self.updatedAt = updatedAt
            self.phone = phone
            self.bed = bed
            self.ownerID = ownerID
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

        func canMoveTo(_ next: AdaptiveHandoffDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveHandoffDigestStatus.expired
            case .granted:
                return next == AdaptiveHandoffDigestStatus.revoked
            case .revoked:
                return next == AdaptiveHandoffDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveHandoffDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive handoff digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((dosageMg - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveHandoffDigest {
            return AdaptiveHandoffDigest(
                code: code,
                label: label,
                dosageMg: dosageMg,
                title: title,
                updatedAt: updatedAt,
                phone: phone,
                bed: bed,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive handoff digest in status requested.
    static func newAdaptiveHandoffDigest(_ code: String, label: String) -> AdaptiveHandoffDigest {
        return AdaptiveHandoffDigest(
            code: code,
            label: label,
            dosageMg: 0.0,
            title: "",
            updatedAt: 0,
            phone: "",
            bed: "",
            ownerID: "",
            status: AdaptiveHandoffDigestStatus.requested
        )
    }
}
