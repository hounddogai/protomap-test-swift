import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual result window is in its life cycle.
    enum ManualResultWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual result window. Its code is unique within a tenant.
    final class ManualResultWindow {
        var code: String
        var name: String
        var threshold: Double
        var windowDays: Int
        var segment: String
        var ratio: Double
        var durationMinutes: Int
        var visitMinutes: Int
        var visible: Bool
        var graceDays: Int
        var ward: String
        var status: ManualResultWindowStatus

        init(code: String, name: String, threshold: Double, windowDays: Int, segment: String, ratio: Double, durationMinutes: Int, visitMinutes: Int, visible: Bool, graceDays: Int, ward: String, status: ManualResultWindowStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.windowDays = windowDays
            self.segment = segment
            self.ratio = ratio
            self.durationMinutes = durationMinutes
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.graceDays = graceDays
            self.ward = ward
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

        func canMoveTo(_ next: ManualResultWindowStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualResultWindowStatus.resolved || next == ManualResultWindowStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualResultWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual result window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return ((threshold - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ManualResultWindow {
            return ManualResultWindow(
                code: code,
                name: name,
                threshold: threshold,
                windowDays: windowDays,
                segment: segment,
                ratio: ratio,
                durationMinutes: durationMinutes,
                visitMinutes: visitMinutes,
                visible: visible,
                graceDays: graceDays,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual result window in status open.
    static func newManualResultWindow(_ code: String, name: String) -> ManualResultWindow {
        return ManualResultWindow(
            code: code,
            name: name,
            threshold: 0.0,
            windowDays: 0,
            segment: "",
            ratio: 0.0,
            durationMinutes: 0,
            visitMinutes: 0,
            visible: false,
            graceDays: 0,
            ward: "",
            status: ManualResultWindowStatus.`open`
        )
    }
}
