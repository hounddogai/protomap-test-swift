import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality draft is in its life cycle.
    enum ModalityDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A modality draft. Its code is unique within a tenant.
    final class ModalityDraft {
        var code: String
        var name: String
        var acuity: Int
        var externalRef: String
        var expiresAt: Int
        var label: String
        var clinicianID: String
        var quantity: Int
        var status: ModalityDraftStatus

        init(code: String, name: String, acuity: Int, externalRef: String, expiresAt: Int, label: String, clinicianID: String, quantity: Int, status: ModalityDraftStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.label = label
            self.clinicianID = clinicianID
            self.quantity = quantity
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

        func canMoveTo(_ next: ModalityDraftStatus) -> Bool {
            switch status {
            case .requested:
                return next == ModalityDraftStatus.expired
            case .granted:
                return next == ModalityDraftStatus.revoked || next == ModalityDraftStatus.expired
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

        func moveTo(_ next: ModalityDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return ((Double(expiresAt) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityDraft {
            return ModalityDraft(
                code: code,
                name: name,
                acuity: acuity,
                externalRef: externalRef,
                expiresAt: expiresAt,
                label: label,
                clinicianID: clinicianID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a modality draft in status requested.
    static func newModalityDraft(_ code: String, name: String) -> ModalityDraft {
        return ModalityDraft(
            code: code,
            name: name,
            acuity: 0,
            externalRef: "",
            expiresAt: 0,
            label: "",
            clinicianID: "",
            quantity: 0,
            status: ModalityDraftStatus.requested
        )
    }
}
