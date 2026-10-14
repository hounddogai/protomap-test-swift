import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal overtime record is in its life cycle.
    enum SeasonalOvertimeRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A seasonal overtime record. Its code is unique within a tenant.
    final class SeasonalOvertimeRecord {
        var code: String
        var label: String
        var minimum: Double
        var limit: Int
        var ratio: Double
        var status: SeasonalOvertimeRecordStatus

        init(code: String, label: String, minimum: Double, limit: Int, ratio: Double, status: SeasonalOvertimeRecordStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.limit = limit
            self.ratio = ratio
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

        func canMoveTo(_ next: SeasonalOvertimeRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SeasonalOvertimeRecordStatus.inReview
            case .inReview:
                return next == SeasonalOvertimeRecordStatus.archived
            case .resolved:
                return next == SeasonalOvertimeRecordStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SeasonalOvertimeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal overtime record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal overtime record") \(code)"
        }

        func netVolume() -> Double {
            return ((ratio - minimum) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalOvertimeRecord {
            return SeasonalOvertimeRecord(
                code: code,
                label: label,
                minimum: minimum,
                limit: limit,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal overtime record in status open.
    static func newSeasonalOvertimeRecord(_ code: String, label: String) -> SeasonalOvertimeRecord {
        return SeasonalOvertimeRecord(
            code: code,
            label: label,
            minimum: 0.0,
            limit: 0,
            ratio: 0.0,
            status: SeasonalOvertimeRecordStatus.`open`
        )
    }
}
