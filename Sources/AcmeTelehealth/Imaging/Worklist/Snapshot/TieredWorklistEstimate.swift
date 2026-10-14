import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered worklist estimate is in its life cycle.
    enum TieredWorklistEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One tiered worklist estimate, with what the planners need to act on it.
    final class TieredWorklistEstimate {
        var code: String
        var title: String
        var phone: String
        var patientRef: String
        var windowDays: Int
        var durationMinutes: Int
        var status: TieredWorklistEstimateStatus

        init(code: String, title: String, phone: String, patientRef: String, windowDays: Int, durationMinutes: Int, status: TieredWorklistEstimateStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredWorklistEstimateStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredWorklistEstimateStatus.published
            case .validated:
                return next == TieredWorklistEstimateStatus.published || next == TieredWorklistEstimateStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: TieredWorklistEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered worklist estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(durationMinutes) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredWorklistEstimate {
            return TieredWorklistEstimate(
                code: code,
                title: title,
                phone: phone,
                patientRef: patientRef,
                windowDays: windowDays,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered worklist estimate in status created.
    static func newTieredWorklistEstimate(_ code: String, title: String) -> TieredWorklistEstimate {
        return TieredWorklistEstimate(
            code: code,
            title: title,
            phone: "",
            patientRef: "",
            windowDays: 0,
            durationMinutes: 0,
            status: TieredWorklistEstimateStatus.created
        )
    }
}
