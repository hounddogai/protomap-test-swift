import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional overtime entry is in its life cycle.
    enum RegionalOvertimeEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional overtime entry and its current status.
    final class RegionalOvertimeEntry {
        var code: String
        var name: String
        var region: String
        var windowDays: Int
        var procedureCode: String
        var rate: Double
        var discount: Double
        var title: String
        var status: RegionalOvertimeEntryStatus

        init(code: String, name: String, region: String, windowDays: Int, procedureCode: String, rate: Double, discount: Double, title: String, status: RegionalOvertimeEntryStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.windowDays = windowDays
            self.procedureCode = procedureCode
            self.rate = rate
            self.discount = discount
            self.title = title
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

        func canMoveTo(_ next: RegionalOvertimeEntryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalOvertimeEntryStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalOvertimeEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOvertimeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional overtime entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((discount + rate) * 100).rounded() / 100
        }

        func copyValue() -> RegionalOvertimeEntry {
            return RegionalOvertimeEntry(
                code: code,
                name: name,
                region: region,
                windowDays: windowDays,
                procedureCode: procedureCode,
                rate: rate,
                discount: discount,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional overtime entry in status planned.
    static func newRegionalOvertimeEntry(_ code: String, name: String) -> RegionalOvertimeEntry {
        return RegionalOvertimeEntry(
            code: code,
            name: name,
            region: "",
            windowDays: 0,
            procedureCode: "",
            rate: 0.0,
            discount: 0.0,
            title: "",
            status: RegionalOvertimeEntryStatus.planned
        )
    }
}
