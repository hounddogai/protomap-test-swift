import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning bundle is in its life cycle.
    enum CleaningBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A cleaning bundle. Its code is unique within a tenant.
    final class CleaningBundle {
        var code: String
        var title: String
        var source: String
        var payer: String
        var budget: Double
        var checksum: String
        var timezone: String
        var clinicianID: String
        var status: CleaningBundleStatus

        init(code: String, title: String, source: String, payer: String, budget: Double, checksum: String, timezone: String, clinicianID: String, status: CleaningBundleStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.payer = payer
            self.budget = budget
            self.checksum = checksum
            self.timezone = timezone
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: CleaningBundleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CleaningBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> CleaningBundle {
            return CleaningBundle(
                code: code,
                title: title,
                source: source,
                payer: payer,
                budget: budget,
                checksum: checksum,
                timezone: timezone,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a cleaning bundle in status requested.
    static func newCleaningBundle(_ code: String, title: String) -> CleaningBundle {
        return CleaningBundle(
            code: code,
            title: title,
            source: "",
            payer: "",
            budget: 0.0,
            checksum: "",
            timezone: "",
            clinicianID: "",
            status: CleaningBundleStatus.requested
        )
    }
}
