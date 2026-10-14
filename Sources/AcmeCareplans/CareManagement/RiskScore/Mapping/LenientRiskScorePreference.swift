import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient risk score preference is in its life cycle.
    enum LenientRiskScorePreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient risk score preference and its current status.
    final class LenientRiskScorePreference {
        var code: String
        var title: String
        var bed: String
        var graceDays: Int
        var notes: String
        var checksum: String
        var version: Int
        var phone: String
        var active: Bool
        var status: LenientRiskScorePreferenceStatus

        init(code: String, title: String, bed: String, graceDays: Int, notes: String, checksum: String, version: Int, phone: String, active: Bool, status: LenientRiskScorePreferenceStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.graceDays = graceDays
            self.notes = notes
            self.checksum = checksum
            self.version = version
            self.phone = phone
            self.active = active
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

        func canMoveTo(_ next: LenientRiskScorePreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientRiskScorePreferenceStatus.resolved || next == LenientRiskScorePreferenceStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LenientRiskScorePreferenceStatus.reopened || next == LenientRiskScorePreferenceStatus.archived
            case .reopened:
                return next == LenientRiskScorePreferenceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientRiskScorePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient risk score preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("lenient risk score preference") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(graceDays) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> LenientRiskScorePreference {
            return LenientRiskScorePreference(
                code: code,
                title: title,
                bed: bed,
                graceDays: graceDays,
                notes: notes,
                checksum: checksum,
                version: version,
                phone: phone,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient risk score preference in status open.
    static func newLenientRiskScorePreference(_ code: String, title: String) -> LenientRiskScorePreference {
        return LenientRiskScorePreference(
            code: code,
            title: title,
            bed: "",
            graceDays: 0,
            notes: "",
            checksum: "",
            version: 0,
            phone: "",
            active: false,
            status: LenientRiskScorePreferenceStatus.`open`
        )
    }
}
