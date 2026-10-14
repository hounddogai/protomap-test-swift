import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy task window is in its life cycle.
    enum LegacyTaskWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy task window. Its code is unique within a tenant.
    final class LegacyTaskWindow {
        var code: String
        var title: String
        var checksum: String
        var country: String
        var acuity: Int
        var encounterID: String
        var phone: String
        var status: LegacyTaskWindowStatus

        init(code: String, title: String, checksum: String, country: String, acuity: Int, encounterID: String, phone: String, status: LegacyTaskWindowStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.country = country
            self.acuity = acuity
            self.encounterID = encounterID
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyTaskWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyTaskWindowStatus.reopened
            case .inReview:
                return next == LegacyTaskWindowStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LegacyTaskWindowStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyTaskWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy task window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> LegacyTaskWindow {
            return LegacyTaskWindow(
                code: code,
                title: title,
                checksum: checksum,
                country: country,
                acuity: acuity,
                encounterID: encounterID,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a legacy task window in status open.
    static func newLegacyTaskWindow(_ code: String, title: String) -> LegacyTaskWindow {
        return LegacyTaskWindow(
            code: code,
            title: title,
            checksum: "",
            country: "",
            acuity: 0,
            encounterID: "",
            phone: "",
            status: LegacyTaskWindowStatus.`open`
        )
    }
}
