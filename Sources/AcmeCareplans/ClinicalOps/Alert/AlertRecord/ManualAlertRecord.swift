import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual alert record is in its life cycle.
    enum ManualAlertRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual alert record. Its code is unique within a tenant.
    final class ManualAlertRecord {
        var code: String
        var title: String
        var copay: Double
        var batchSize: Int
        var weight: Double
        var contactEmail: String
        var status: ManualAlertRecordStatus

        init(code: String, title: String, copay: Double, batchSize: Int, weight: Double, contactEmail: String, status: ManualAlertRecordStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.batchSize = batchSize
            self.weight = weight
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ManualAlertRecordStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ManualAlertRecordStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualAlertRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual alert record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual alert record") \(code)"
        }

        func weightedTotal() -> Double {
            return (weight * copay * 100).rounded() / 100
        }

        func copyValue() -> ManualAlertRecord {
            return ManualAlertRecord(
                code: code,
                title: title,
                copay: copay,
                batchSize: batchSize,
                weight: weight,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual alert record in status requested.
    static func newManualAlertRecord(_ code: String, title: String) -> ManualAlertRecord {
        return ManualAlertRecord(
            code: code,
            title: title,
            copay: 0.0,
            batchSize: 0,
            weight: 0.0,
            contactEmail: "",
            status: ManualAlertRecordStatus.requested
        )
    }
}
