import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback courier exception is in its life cycle.
    enum FallbackCourierExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a fallback courier exception and its current status.
    final class FallbackCourierException {
        var code: String
        var title: String
        var minimum: Double
        var visible: Bool
        var name: String
        var maximum: Double
        var graceDays: Int
        var summary: String
        var status: FallbackCourierExceptionStatus

        init(code: String, title: String, minimum: Double, visible: Bool, name: String, maximum: Double, graceDays: Int, summary: String, status: FallbackCourierExceptionStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.visible = visible
            self.name = name
            self.maximum = maximum
            self.graceDays = graceDays
            self.summary = summary
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

        func canMoveTo(_ next: FallbackCourierExceptionStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FallbackCourierExceptionStatus.retired
            case .published:
                return next == FallbackCourierExceptionStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCourierExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback courier exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback courier exception") \(code)"
        }

        func effectiveVolume() -> Double {
            return (maximum * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCourierException {
            return FallbackCourierException(
                code: code,
                title: title,
                minimum: minimum,
                visible: visible,
                name: name,
                maximum: maximum,
                graceDays: graceDays,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback courier exception in status created.
    static func newFallbackCourierException(_ code: String, title: String) -> FallbackCourierException {
        return FallbackCourierException(
            code: code,
            title: title,
            minimum: 0.0,
            visible: false,
            name: "",
            maximum: 0.0,
            graceDays: 0,
            summary: "",
            status: FallbackCourierExceptionStatus.created
        )
    }
}
