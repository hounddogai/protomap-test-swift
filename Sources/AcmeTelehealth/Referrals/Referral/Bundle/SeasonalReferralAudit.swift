import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal referral audit is in its life cycle.
    enum SeasonalReferralAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal referral audit as the referral team keeps it.
    final class SeasonalReferralAudit {
        var code: String
        var label: String
        var checksum: String
        var unit: String
        var patientRef: String
        var name: String
        var score: Double
        var status: SeasonalReferralAuditStatus

        init(code: String, label: String, checksum: String, unit: String, patientRef: String, name: String, score: Double, status: SeasonalReferralAuditStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.unit = unit
            self.patientRef = patientRef
            self.name = name
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalReferralAuditStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SeasonalReferralAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal referral audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal referral audit") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> SeasonalReferralAudit {
            return SeasonalReferralAudit(
                code: code,
                label: label,
                checksum: checksum,
                unit: unit,
                patientRef: patientRef,
                name: name,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a seasonal referral audit in status created.
    static func newSeasonalReferralAudit(_ code: String, label: String) -> SeasonalReferralAudit {
        return SeasonalReferralAudit(
            code: code,
            label: label,
            checksum: "",
            unit: "",
            patientRef: "",
            name: "",
            score: 0.0,
            status: SeasonalReferralAuditStatus.created
        )
    }
}
