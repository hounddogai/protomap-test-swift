import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual modality mapping is in its life cycle.
    enum ManualModalityMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual modality mapping. Its code is unique within a tenant.
    final class ManualModalityMapping {
        var code: String
        var title: String
        var updatedAt: Int
        var expiresAt: Int
        var acuity: Int
        var contactEmail: String
        var externalRef: String
        var copay: Double
        var currency: String
        var status: ManualModalityMappingStatus

        init(code: String, title: String, updatedAt: Int, expiresAt: Int, acuity: Int, contactEmail: String, externalRef: String, copay: Double, currency: String, status: ManualModalityMappingStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.contactEmail = contactEmail
            self.externalRef = externalRef
            self.copay = copay
            self.currency = currency
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

        func canMoveTo(_ next: ManualModalityMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ManualModalityMappingStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualModalityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual modality mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual modality mapping") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) + copay) * 100).rounded() / 100
        }

        func copyValue() -> ManualModalityMapping {
            return ManualModalityMapping(
                code: code,
                title: title,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                acuity: acuity,
                contactEmail: contactEmail,
                externalRef: externalRef,
                copay: copay,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual modality mapping in status planned.
    static func newManualModalityMapping(_ code: String, title: String) -> ManualModalityMapping {
        return ManualModalityMapping(
            code: code,
            title: title,
            updatedAt: 0,
            expiresAt: 0,
            acuity: 0,
            contactEmail: "",
            externalRef: "",
            copay: 0.0,
            currency: "",
            status: ManualModalityMappingStatus.planned
        )
    }
}
