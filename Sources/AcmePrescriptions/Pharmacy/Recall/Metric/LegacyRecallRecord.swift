import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy recall record is in its life cycle.
    enum LegacyRecallRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy recall record. Its code is unique within a tenant.
    final class LegacyRecallRecord {
        var code: String
        var title: String
        var channel: String
        var region: String
        var diagnosisCode: String
        var externalRef: String
        var score: Double
        var status: LegacyRecallRecordStatus

        init(code: String, title: String, channel: String, region: String, diagnosisCode: String, externalRef: String, score: Double, status: LegacyRecallRecordStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.externalRef = externalRef
            self.score = score
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

        func canMoveTo(_ next: LegacyRecallRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyRecallRecordStatus.inProgress
            case .scheduled:
                return next == LegacyRecallRecordStatus.inProgress || next == LegacyRecallRecordStatus.completed
            case .inProgress:
                return next == LegacyRecallRecordStatus.completed
            case .completed:
                return next == LegacyRecallRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyRecallRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy recall record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy recall record") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> LegacyRecallRecord {
            return LegacyRecallRecord(
                code: code,
                title: title,
                channel: channel,
                region: region,
                diagnosisCode: diagnosisCode,
                externalRef: externalRef,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy recall record in status planned.
    static func newLegacyRecallRecord(_ code: String, title: String) -> LegacyRecallRecord {
        return LegacyRecallRecord(
            code: code,
            title: title,
            channel: "",
            region: "",
            diagnosisCode: "",
            externalRef: "",
            score: 0.0,
            status: LegacyRecallRecordStatus.planned
        )
    }
}
