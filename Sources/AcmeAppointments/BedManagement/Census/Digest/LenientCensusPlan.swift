import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient census plan is in its life cycle.
    enum LenientCensusPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient census plan. Its code is unique within a tenant.
    final class LenientCensusPlan {
        var code: String
        var title: String
        var timezone: String
        var limit: Int
        var diagnosisCode: String
        var source: String
        var batchSize: Int
        var clinicianID: String
        var attempts: Int
        var status: LenientCensusPlanStatus

        init(code: String, title: String, timezone: String, limit: Int, diagnosisCode: String, source: String, batchSize: Int, clinicianID: String, attempts: Int, status: LenientCensusPlanStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.limit = limit
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.batchSize = batchSize
            self.clinicianID = clinicianID
            self.attempts = attempts
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

        func canMoveTo(_ next: LenientCensusPlanStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LenientCensusPlanStatus.completed
            case .inProgress:
                return next == LenientCensusPlanStatus.completed || next == LenientCensusPlanStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LenientCensusPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient census plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedLoad() -> Double {
            return ((Double(attempts) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LenientCensusPlan {
            return LenientCensusPlan(
                code: code,
                title: title,
                timezone: timezone,
                limit: limit,
                diagnosisCode: diagnosisCode,
                source: source,
                batchSize: batchSize,
                clinicianID: clinicianID,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient census plan in status planned.
    static func newLenientCensusPlan(_ code: String, title: String) -> LenientCensusPlan {
        return LenientCensusPlan(
            code: code,
            title: title,
            timezone: "",
            limit: 0,
            diagnosisCode: "",
            source: "",
            batchSize: 0,
            clinicianID: "",
            attempts: 0,
            status: LenientCensusPlanStatus.planned
        )
    }
}
