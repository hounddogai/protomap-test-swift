import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict isolation schedule is in its life cycle.
    enum StrictIsolationScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict isolation schedule. Its code is unique within a tenant.
    final class StrictIsolationSchedule {
        var code: String
        var label: String
        var title: String
        var ownerID: String
        var reviewer: String
        var unit: String
        var payer: String
        var locale: String
        var source: String
        var score: Double
        var status: StrictIsolationScheduleStatus

        init(code: String, label: String, title: String, ownerID: String, reviewer: String, unit: String, payer: String, locale: String, source: String, score: Double, status: StrictIsolationScheduleStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.unit = unit
            self.payer = payer
            self.locale = locale
            self.source = source
            self.score = score
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

        func canMoveTo(_ next: StrictIsolationScheduleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == StrictIsolationScheduleStatus.suspended || next == StrictIsolationScheduleStatus.closed
            case .active:
                return next == StrictIsolationScheduleStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StrictIsolationScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict isolation schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> StrictIsolationSchedule {
            return StrictIsolationSchedule(
                code: code,
                label: label,
                title: title,
                ownerID: ownerID,
                reviewer: reviewer,
                unit: unit,
                payer: payer,
                locale: locale,
                source: source,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict isolation schedule in status draft.
    static func newStrictIsolationSchedule(_ code: String, label: String) -> StrictIsolationSchedule {
        return StrictIsolationSchedule(
            code: code,
            label: label,
            title: "",
            ownerID: "",
            reviewer: "",
            unit: "",
            payer: "",
            locale: "",
            source: "",
            score: 0.0,
            status: StrictIsolationScheduleStatus.draft
        )
    }
}
