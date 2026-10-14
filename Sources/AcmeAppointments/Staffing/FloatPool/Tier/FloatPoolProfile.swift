import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool profile is in its life cycle.
    enum FloatPoolProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One float pool profile, with what the planners need to act on it.
    final class FloatPoolProfile {
        var code: String
        var label: String
        var maximum: Double
        var bed: String
        var approved: Bool
        var retries: Int
        var rate: Double
        var status: FloatPoolProfileStatus

        init(code: String, label: String, maximum: Double, bed: String, approved: Bool, retries: Int, rate: Double, status: FloatPoolProfileStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.bed = bed
            self.approved = approved
            self.retries = retries
            self.rate = rate
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

        func canMoveTo(_ next: FloatPoolProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FloatPoolProfileStatus.suspended
            case .active:
                return next == FloatPoolProfileStatus.suspended
            case .suspended:
                return next == FloatPoolProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return (rate * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolProfile {
            return FloatPoolProfile(
                code: code,
                label: label,
                maximum: maximum,
                bed: bed,
                approved: approved,
                retries: retries,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool profile in status draft.
    static func newFloatPoolProfile(_ code: String, label: String) -> FloatPoolProfile {
        return FloatPoolProfile(
            code: code,
            label: label,
            maximum: 0.0,
            bed: "",
            approved: false,
            retries: 0,
            rate: 0.0,
            status: FloatPoolProfileStatus.draft
        )
    }
}
