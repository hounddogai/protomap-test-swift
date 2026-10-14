import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback acuity plan request is in its life cycle.
    enum FallbackAcuityPlanRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback acuity plan request, with what the planners need to act on it.
    final class FallbackAcuityPlanRequest {
        var code: String
        var name: String
        var maximum: Double
        var margin: Double
        var title: String
        var rate: Double
        var visible: Bool
        var status: FallbackAcuityPlanRequestStatus

        init(code: String, name: String, maximum: Double, margin: Double, title: String, rate: Double, visible: Bool, status: FallbackAcuityPlanRequestStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.margin = margin
            self.title = title
            self.rate = rate
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackAcuityPlanRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: FallbackAcuityPlanRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback acuity plan request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback acuity plan request") \(code)"
        }

        func adjustedTotal() -> Double {
            return (rate * margin * 100).rounded() / 100
        }

        func copyValue() -> FallbackAcuityPlanRequest {
            return FallbackAcuityPlanRequest(
                code: code,
                name: name,
                maximum: maximum,
                margin: margin,
                title: title,
                rate: rate,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback acuity plan request in status new.
    static func newFallbackAcuityPlanRequest(_ code: String, name: String) -> FallbackAcuityPlanRequest {
        return FallbackAcuityPlanRequest(
            code: code,
            name: name,
            maximum: 0.0,
            margin: 0.0,
            title: "",
            rate: 0.0,
            visible: false,
            status: FallbackAcuityPlanRequestStatus.new
        )
    }
}
