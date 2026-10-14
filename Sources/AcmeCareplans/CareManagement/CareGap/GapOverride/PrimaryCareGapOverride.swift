import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary care gap override is in its life cycle.
    enum PrimaryCareGapOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a primary care gap override and its current status.
    final class PrimaryCareGapOverride {
        var code: String
        var title: String
        var facility: String
        var timezone: String
        var visitMinutes: Int
        var cost: Double
        var status: PrimaryCareGapOverrideStatus

        init(code: String, title: String, facility: String, timezone: String, visitMinutes: Int, cost: Double, status: PrimaryCareGapOverrideStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.timezone = timezone
            self.visitMinutes = visitMinutes
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryCareGapOverrideStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimaryCareGapOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCareGapOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care gap override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return ((cost + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCareGapOverride {
            return PrimaryCareGapOverride(
                code: code,
                title: title,
                facility: facility,
                timezone: timezone,
                visitMinutes: visitMinutes,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a primary care gap override in status idle.
    static func newPrimaryCareGapOverride(_ code: String, title: String) -> PrimaryCareGapOverride {
        return PrimaryCareGapOverride(
            code: code,
            title: title,
            facility: "",
            timezone: "",
            visitMinutes: 0,
            cost: 0.0,
            status: PrimaryCareGapOverrideStatus.idle
        )
    }
}
