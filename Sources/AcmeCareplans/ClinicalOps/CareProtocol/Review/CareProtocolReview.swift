import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol review is in its life cycle.
    enum CareProtocolReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One care protocol review, with what the planners need to act on it.
    final class CareProtocolReview {
        var code: String
        var label: String
        var unit: String
        var retries: Int
        var durationMinutes: Int
        var encounterID: String
        var channel: String
        var ceiling: Double
        var diagnosisCode: String
        var source: String
        var phone: String
        var status: CareProtocolReviewStatus

        init(code: String, label: String, unit: String, retries: Int, durationMinutes: Int, encounterID: String, channel: String, ceiling: Double, diagnosisCode: String, source: String, phone: String, status: CareProtocolReviewStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.retries = retries
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.channel = channel
            self.ceiling = ceiling
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolReviewStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CareProtocolReviewStatus.suspended
            case .suspended:
                return next == CareProtocolReviewStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedVolume() -> Double {
            return ((Double(durationMinutes) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolReview {
            return CareProtocolReview(
                code: code,
                label: label,
                unit: unit,
                retries: retries,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                channel: channel,
                ceiling: ceiling,
                diagnosisCode: diagnosisCode,
                source: source,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a care protocol review in status draft.
    static func newCareProtocolReview(_ code: String, label: String) -> CareProtocolReview {
        return CareProtocolReview(
            code: code,
            label: label,
            unit: "",
            retries: 0,
            durationMinutes: 0,
            encounterID: "",
            channel: "",
            ceiling: 0.0,
            diagnosisCode: "",
            source: "",
            phone: "",
            status: CareProtocolReviewStatus.draft
        )
    }
}
