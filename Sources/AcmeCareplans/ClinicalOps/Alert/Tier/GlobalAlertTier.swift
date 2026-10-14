import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global alert tier is in its life cycle.
    enum GlobalAlertTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global alert tier. Its code is unique within a tenant.
    final class GlobalAlertTier {
        var code: String
        var title: String
        var dosageMg: Double
        var encounterID: String
        var expiresAt: Int
        var name: String
        var checksum: String
        var label: String
        var pinned: Bool
        var status: GlobalAlertTierStatus

        init(code: String, title: String, dosageMg: Double, encounterID: String, expiresAt: Int, name: String, checksum: String, label: String, pinned: Bool, status: GlobalAlertTierStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.encounterID = encounterID
            self.expiresAt = expiresAt
            self.name = name
            self.checksum = checksum
            self.label = label
            self.pinned = pinned
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

        func canMoveTo(_ next: GlobalAlertTierStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalAlertTierStatus.validated || next == GlobalAlertTierStatus.retired
            case .validated:
                return next == GlobalAlertTierStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: GlobalAlertTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global alert tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global alert tier") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(expiresAt) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAlertTier {
            return GlobalAlertTier(
                code: code,
                title: title,
                dosageMg: dosageMg,
                encounterID: encounterID,
                expiresAt: expiresAt,
                name: name,
                checksum: checksum,
                label: label,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global alert tier in status created.
    static func newGlobalAlertTier(_ code: String, title: String) -> GlobalAlertTier {
        return GlobalAlertTier(
            code: code,
            title: title,
            dosageMg: 0.0,
            encounterID: "",
            expiresAt: 0,
            name: "",
            checksum: "",
            label: "",
            pinned: false,
            status: GlobalAlertTierStatus.created
        )
    }
}
