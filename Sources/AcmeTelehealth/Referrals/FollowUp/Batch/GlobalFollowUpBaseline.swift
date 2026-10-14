import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global follow up baseline is in its life cycle.
    enum GlobalFollowUpBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global follow up baseline, with what the planners need to act on it.
    final class GlobalFollowUpBaseline {
        var code: String
        var label: String
        var patientRef: String
        var locale: String
        var approved: Bool
        var durationMinutes: Int
        var category: String
        var clinicianID: String
        var endsAt: Int
        var status: GlobalFollowUpBaselineStatus

        init(code: String, label: String, patientRef: String, locale: String, approved: Bool, durationMinutes: Int, category: String, clinicianID: String, endsAt: Int, status: GlobalFollowUpBaselineStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.locale = locale
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.category = category
            self.clinicianID = clinicianID
            self.endsAt = endsAt
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

        func canMoveTo(_ next: GlobalFollowUpBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalFollowUpBaselineStatus.expired
            case .granted:
                return next == GlobalFollowUpBaselineStatus.revoked || next == GlobalFollowUpBaselineStatus.expired
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

        func moveTo(_ next: GlobalFollowUpBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global follow up baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global follow up baseline") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(endsAt) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFollowUpBaseline {
            return GlobalFollowUpBaseline(
                code: code,
                label: label,
                patientRef: patientRef,
                locale: locale,
                approved: approved,
                durationMinutes: durationMinutes,
                category: category,
                clinicianID: clinicianID,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global follow up baseline in status requested.
    static func newGlobalFollowUpBaseline(_ code: String, label: String) -> GlobalFollowUpBaseline {
        return GlobalFollowUpBaseline(
            code: code,
            label: label,
            patientRef: "",
            locale: "",
            approved: false,
            durationMinutes: 0,
            category: "",
            clinicianID: "",
            endsAt: 0,
            status: GlobalFollowUpBaselineStatus.requested
        )
    }
}
