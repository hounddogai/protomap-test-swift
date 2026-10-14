import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict dispense request is in its life cycle.
    enum StrictDispenseRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a strict dispense request and its current status.
    final class StrictDispenseRequest {
        var code: String
        var title: String
        var unit: String
        var ward: String
        var bed: String
        var reviewer: String
        var cost: Double
        var locale: String
        var timezone: String
        var copay: Double
        var status: StrictDispenseRequestStatus

        init(code: String, title: String, unit: String, ward: String, bed: String, reviewer: String, cost: Double, locale: String, timezone: String, copay: Double, status: StrictDispenseRequestStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.ward = ward
            self.bed = bed
            self.reviewer = reviewer
            self.cost = cost
            self.locale = locale
            self.timezone = timezone
            self.copay = copay
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

        func canMoveTo(_ next: StrictDispenseRequestStatus) -> Bool {
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
                return next == StrictDispenseRequestStatus.suspended
            case .active:
                return next == StrictDispenseRequestStatus.closed
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

        func moveTo(_ next: StrictDispenseRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict dispense request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((copay + cost) * 100).rounded() / 100
        }

        func copyValue() -> StrictDispenseRequest {
            return StrictDispenseRequest(
                code: code,
                title: title,
                unit: unit,
                ward: ward,
                bed: bed,
                reviewer: reviewer,
                cost: cost,
                locale: locale,
                timezone: timezone,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict dispense request in status draft.
    static func newStrictDispenseRequest(_ code: String, title: String) -> StrictDispenseRequest {
        return StrictDispenseRequest(
            code: code,
            title: title,
            unit: "",
            ward: "",
            bed: "",
            reviewer: "",
            cost: 0.0,
            locale: "",
            timezone: "",
            copay: 0.0,
            status: StrictDispenseRequestStatus.draft
        )
    }
}
