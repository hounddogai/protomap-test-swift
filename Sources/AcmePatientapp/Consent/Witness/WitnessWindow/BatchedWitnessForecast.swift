import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched witness forecast is in its life cycle.
    enum BatchedWitnessForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched witness forecast. Its code is unique within a tenant.
    final class BatchedWitnessForecast {
        var code: String
        var title: String
        var threshold: Double
        var windowDays: Int
        var visible: Bool
        var version: Int
        var status: BatchedWitnessForecastStatus

        init(code: String, title: String, threshold: Double, windowDays: Int, visible: Bool, version: Int, status: BatchedWitnessForecastStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.windowDays = windowDays
            self.visible = visible
            self.version = version
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

        func canMoveTo(_ next: BatchedWitnessForecastStatus) -> Bool {
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
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BatchedWitnessForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedWitnessForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched witness forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return (threshold * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> BatchedWitnessForecast {
            return BatchedWitnessForecast(
                code: code,
                title: title,
                threshold: threshold,
                windowDays: windowDays,
                visible: visible,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched witness forecast in status open.
    static func newBatchedWitnessForecast(_ code: String, title: String) -> BatchedWitnessForecast {
        return BatchedWitnessForecast(
            code: code,
            title: title,
            threshold: 0.0,
            windowDays: 0,
            visible: false,
            version: 0,
            status: BatchedWitnessForecastStatus.`open`
        )
    }
}
