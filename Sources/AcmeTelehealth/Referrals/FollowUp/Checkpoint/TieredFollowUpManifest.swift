import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered follow up manifest is in its life cycle.
    enum TieredFollowUpManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered follow up manifest. Its code is unique within a tenant.
    final class TieredFollowUpManifest {
        var code: String
        var label: String
        var approved: Bool
        var contactEmail: String
        var discount: Double
        var dosageMg: Double
        var status: TieredFollowUpManifestStatus

        init(code: String, label: String, approved: Bool, contactEmail: String, discount: Double, dosageMg: Double, status: TieredFollowUpManifestStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.contactEmail = contactEmail
            self.discount = discount
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredFollowUpManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == TieredFollowUpManifestStatus.ready
            case .ready:
                return next == TieredFollowUpManifestStatus.draining || next == TieredFollowUpManifestStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: TieredFollowUpManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered follow up manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return ((dosageMg + discount) * 100).rounded() / 100
        }

        func copyValue() -> TieredFollowUpManifest {
            return TieredFollowUpManifest(
                code: code,
                label: label,
                approved: approved,
                contactEmail: contactEmail,
                discount: discount,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered follow up manifest in status idle.
    static func newTieredFollowUpManifest(_ code: String, label: String) -> TieredFollowUpManifest {
        return TieredFollowUpManifest(
            code: code,
            label: label,
            approved: false,
            contactEmail: "",
            discount: 0.0,
            dosageMg: 0.0,
            status: TieredFollowUpManifestStatus.idle
        )
    }
}
