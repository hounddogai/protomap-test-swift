import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional consent form entry is in its life cycle.
    enum RegionalConsentFormEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional consent form entry. Its code is unique within a tenant.
    final class RegionalConsentFormEntry {
        var code: String
        var title: String
        var acuity: Int
        var expiresAt: Int
        var minimum: Double
        var country: String
        var revision: Int
        var approved: Bool
        var visible: Bool
        var version: Int
        var status: RegionalConsentFormEntryStatus

        init(code: String, title: String, acuity: Int, expiresAt: Int, minimum: Double, country: String, revision: Int, approved: Bool, visible: Bool, version: Int, status: RegionalConsentFormEntryStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.country = country
            self.revision = revision
            self.approved = approved
            self.visible = visible
            self.version = version
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

        func canMoveTo(_ next: RegionalConsentFormEntryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalConsentFormEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalConsentFormEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional consent form entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((Double(version) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalConsentFormEntry {
            return RegionalConsentFormEntry(
                code: code,
                title: title,
                acuity: acuity,
                expiresAt: expiresAt,
                minimum: minimum,
                country: country,
                revision: revision,
                approved: approved,
                visible: visible,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional consent form entry in status planned.
    static func newRegionalConsentFormEntry(_ code: String, title: String) -> RegionalConsentFormEntry {
        return RegionalConsentFormEntry(
            code: code,
            title: title,
            acuity: 0,
            expiresAt: 0,
            minimum: 0.0,
            country: "",
            revision: 0,
            approved: false,
            visible: false,
            version: 0,
            status: RegionalConsentFormEntryStatus.planned
        )
    }
}
