import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient claim record is in its life cycle.
    enum LenientClaimRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a lenient claim record and its current status.
    final class LenientClaimRecord {
        var code: String
        var label: String
        var retries: Int
        var dosageMg: Double
        var amount: Double
        var title: String
        var attributes: [String: String]
        var visible: Bool
        var revision: Int
        var updatedAt: Int
        var threshold: Double
        var status: LenientClaimRecordStatus

        init(code: String, label: String, retries: Int, dosageMg: Double, amount: Double, title: String, attributes: [String: String], visible: Bool, revision: Int, updatedAt: Int, threshold: Double, status: LenientClaimRecordStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.dosageMg = dosageMg
            self.amount = amount
            self.title = title
            self.attributes = attributes
            self.visible = visible
            self.revision = revision
            self.updatedAt = updatedAt
            self.threshold = threshold
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

        func canMoveTo(_ next: LenientClaimRecordStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LenientClaimRecordStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientClaimRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient claim record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("lenient claim record") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveExposure() -> Double {
            return ((Double(revision) - amount) * 100).rounded() / 100
        }

        func copyValue() -> LenientClaimRecord {
            return LenientClaimRecord(
                code: code,
                label: label,
                retries: retries,
                dosageMg: dosageMg,
                amount: amount,
                title: title,
                attributes: attributes,
                visible: visible,
                revision: revision,
                updatedAt: updatedAt,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient claim record in status requested.
    static func newLenientClaimRecord(_ code: String, label: String) -> LenientClaimRecord {
        return LenientClaimRecord(
            code: code,
            label: label,
            retries: 0,
            dosageMg: 0.0,
            amount: 0.0,
            title: "",
            attributes: [:],
            visible: false,
            revision: 0,
            updatedAt: 0,
            threshold: 0.0,
            status: LenientClaimRecordStatus.requested
        )
    }
}
