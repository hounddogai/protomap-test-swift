import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global follow up audit is in its life cycle.
    enum GlobalFollowUpAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global follow up audit as the follow up team keeps it.
    final class GlobalFollowUpAudit {
        var code: String
        var label: String
        var startsAt: Int
        var minimum: Double
        var diagnosisCode: String
        var unit: String
        var locale: String
        var status: GlobalFollowUpAuditStatus

        init(code: String, label: String, startsAt: Int, minimum: Double, diagnosisCode: String, unit: String, locale: String, status: GlobalFollowUpAuditStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.minimum = minimum
            self.diagnosisCode = diagnosisCode
            self.unit = unit
            self.locale = locale
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

        func canMoveTo(_ next: GlobalFollowUpAuditStatus) -> Bool {
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
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalFollowUpAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global follow up audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return ((minimum - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFollowUpAudit {
            return GlobalFollowUpAudit(
                code: code,
                label: label,
                startsAt: startsAt,
                minimum: minimum,
                diagnosisCode: diagnosisCode,
                unit: unit,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global follow up audit in status requested.
    static func newGlobalFollowUpAudit(_ code: String, label: String) -> GlobalFollowUpAudit {
        return GlobalFollowUpAudit(
            code: code,
            label: label,
            startsAt: 0,
            minimum: 0.0,
            diagnosisCode: "",
            unit: "",
            locale: "",
            status: GlobalFollowUpAuditStatus.requested
        )
    }
}
