import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment preference is in its life cycle.
    enum AssessmentPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A assessment preference. Its code is unique within a tenant.
    final class AssessmentPreference {
        var code: String
        var title: String
        var active: Bool
        var cost: Double
        var acuity: Int
        var version: Int
        var graceDays: Int
        var startsAt: Int
        var refills: Int
        var channel: String
        var payer: String
        var status: AssessmentPreferenceStatus

        init(code: String, title: String, active: Bool, cost: Double, acuity: Int, version: Int, graceDays: Int, startsAt: Int, refills: Int, channel: String, payer: String, status: AssessmentPreferenceStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.cost = cost
            self.acuity = acuity
            self.version = version
            self.graceDays = graceDays
            self.startsAt = startsAt
            self.refills = refills
            self.channel = channel
            self.payer = payer
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

        func canMoveTo(_ next: AssessmentPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == AssessmentPreferenceStatus.granted || next == AssessmentPreferenceStatus.expired
            case .granted:
                return next == AssessmentPreferenceStatus.expired
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

        func moveTo(_ next: AssessmentPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return (Double(refills) * cost * 100).rounded() / 100
        }

        func copyValue() -> AssessmentPreference {
            return AssessmentPreference(
                code: code,
                title: title,
                active: active,
                cost: cost,
                acuity: acuity,
                version: version,
                graceDays: graceDays,
                startsAt: startsAt,
                refills: refills,
                channel: channel,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a assessment preference in status requested.
    static func newAssessmentPreference(_ code: String, title: String) -> AssessmentPreference {
        return AssessmentPreference(
            code: code,
            title: title,
            active: false,
            cost: 0.0,
            acuity: 0,
            version: 0,
            graceDays: 0,
            startsAt: 0,
            refills: 0,
            channel: "",
            payer: "",
            status: AssessmentPreferenceStatus.requested
        )
    }
}
