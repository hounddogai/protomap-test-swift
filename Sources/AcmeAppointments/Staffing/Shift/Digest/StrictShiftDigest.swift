import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict shift digest is in its life cycle.
    enum StrictShiftDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict shift digest. Its code is unique within a tenant.
    final class StrictShiftDigest {
        var code: String
        var title: String
        var allergy: String
        var payer: String
        var diagnosisCode: String
        var limit: Int
        var currency: String
        var status: StrictShiftDigestStatus

        init(code: String, title: String, allergy: String, payer: String, diagnosisCode: String, limit: Int, currency: String, status: StrictShiftDigestStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.payer = payer
            self.diagnosisCode = diagnosisCode
            self.limit = limit
            self.currency = currency
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

        func canMoveTo(_ next: StrictShiftDigestStatus) -> Bool {
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
                return next == StrictShiftDigestStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == StrictShiftDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictShiftDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict shift digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict shift digest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> StrictShiftDigest {
            return StrictShiftDigest(
                code: code,
                title: title,
                allergy: allergy,
                payer: payer,
                diagnosisCode: diagnosisCode,
                limit: limit,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict shift digest in status planned.
    static func newStrictShiftDigest(_ code: String, title: String) -> StrictShiftDigest {
        return StrictShiftDigest(
            code: code,
            title: title,
            allergy: "",
            payer: "",
            diagnosisCode: "",
            limit: 0,
            currency: "",
            status: StrictShiftDigestStatus.planned
        )
    }
}
