import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling float pool score is in its life cycle.
    enum RollingFloatPoolScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling float pool score. Its code is unique within a tenant.
    final class RollingFloatPoolScore {
        var code: String
        var label: String
        var budget: Double
        var bed: String
        var limit: Int
        var encounterID: String
        var locale: String
        var visitMinutes: Int
        var retries: Int
        var threshold: Double
        var status: RollingFloatPoolScoreStatus

        init(code: String, label: String, budget: Double, bed: String, limit: Int, encounterID: String, locale: String, visitMinutes: Int, retries: Int, threshold: Double, status: RollingFloatPoolScoreStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.bed = bed
            self.limit = limit
            self.encounterID = encounterID
            self.locale = locale
            self.visitMinutes = visitMinutes
            self.retries = retries
            self.threshold = threshold
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

        func canMoveTo(_ next: RollingFloatPoolScoreStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
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

        func moveTo(_ next: RollingFloatPoolScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling float pool score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((threshold + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RollingFloatPoolScore {
            return RollingFloatPoolScore(
                code: code,
                label: label,
                budget: budget,
                bed: bed,
                limit: limit,
                encounterID: encounterID,
                locale: locale,
                visitMinutes: visitMinutes,
                retries: retries,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling float pool score in status requested.
    static func newRollingFloatPoolScore(_ code: String, label: String) -> RollingFloatPoolScore {
        return RollingFloatPoolScore(
            code: code,
            label: label,
            budget: 0.0,
            bed: "",
            limit: 0,
            encounterID: "",
            locale: "",
            visitMinutes: 0,
            retries: 0,
            threshold: 0.0,
            status: RollingFloatPoolScoreStatus.requested
        )
    }
}
