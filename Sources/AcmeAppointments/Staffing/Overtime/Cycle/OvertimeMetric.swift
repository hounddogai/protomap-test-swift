import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime metric is in its life cycle.
    enum OvertimeMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One overtime metric, with what the planners need to act on it.
    final class OvertimeMetric {
        var code: String
        var title: String
        var revision: Int
        var phone: String
        var pinned: Bool
        var segment: String
        var dosageMg: Double
        var status: OvertimeMetricStatus

        init(code: String, title: String, revision: Int, phone: String, pinned: Bool, segment: String, dosageMg: Double, status: OvertimeMetricStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.phone = phone
            self.pinned = pinned
            self.segment = segment
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: OvertimeMetricStatus) -> Bool {
            switch status {
            case .draft:
                return next == OvertimeMetricStatus.active
            case .pending:
                return next == OvertimeMetricStatus.active
            case .active:
                return next == OvertimeMetricStatus.suspended
            case .suspended:
                return next == OvertimeMetricStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("overtime metric") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((dosageMg - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeMetric {
            return OvertimeMetric(
                code: code,
                title: title,
                revision: revision,
                phone: phone,
                pinned: pinned,
                segment: segment,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a overtime metric in status draft.
    static func newOvertimeMetric(_ code: String, title: String) -> OvertimeMetric {
        return OvertimeMetric(
            code: code,
            title: title,
            revision: 0,
            phone: "",
            pinned: false,
            segment: "",
            dosageMg: 0.0,
            status: OvertimeMetricStatus.draft
        )
    }
}
