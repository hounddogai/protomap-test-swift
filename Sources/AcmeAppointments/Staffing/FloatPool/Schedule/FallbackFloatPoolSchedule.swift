import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback float pool schedule is in its life cycle.
    enum FallbackFloatPoolScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback float pool schedule. Its code is unique within a tenant.
    final class FallbackFloatPoolSchedule {
        var code: String
        var title: String
        var payer: String
        var threshold: Double
        var graceDays: Int
        var revision: Int
        var country: String
        var region: String
        var cost: Double
        var status: FallbackFloatPoolScheduleStatus

        init(code: String, title: String, payer: String, threshold: Double, graceDays: Int, revision: Int, country: String, region: String, cost: Double, status: FallbackFloatPoolScheduleStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.threshold = threshold
            self.graceDays = graceDays
            self.revision = revision
            self.country = country
            self.region = region
            self.cost = cost
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

        func canMoveTo(_ next: FallbackFloatPoolScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackFloatPoolScheduleStatus.scheduled || next == FallbackFloatPoolScheduleStatus.inProgress
            case .scheduled:
                return next == FallbackFloatPoolScheduleStatus.inProgress || next == FallbackFloatPoolScheduleStatus.cancelled
            case .inProgress:
                return next == FallbackFloatPoolScheduleStatus.completed || next == FallbackFloatPoolScheduleStatus.cancelled
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

        func moveTo(_ next: FallbackFloatPoolScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback float pool schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return (Double(revision) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFloatPoolSchedule {
            return FallbackFloatPoolSchedule(
                code: code,
                title: title,
                payer: payer,
                threshold: threshold,
                graceDays: graceDays,
                revision: revision,
                country: country,
                region: region,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback float pool schedule in status planned.
    static func newFallbackFloatPoolSchedule(_ code: String, title: String) -> FallbackFloatPoolSchedule {
        return FallbackFloatPoolSchedule(
            code: code,
            title: title,
            payer: "",
            threshold: 0.0,
            graceDays: 0,
            revision: 0,
            country: "",
            region: "",
            cost: 0.0,
            status: FallbackFloatPoolScheduleStatus.planned
        )
    }
}
