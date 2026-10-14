import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global isolation request is in its life cycle.
    enum GlobalIsolationRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global isolation request as the isolation team keeps it.
    final class GlobalIsolationRequest {
        var code: String
        var title: String
        var source: String
        var region: String
        var summary: String
        var checksum: String
        var active: Bool
        var segment: String
        var rate: Double
        var status: GlobalIsolationRequestStatus

        init(code: String, title: String, source: String, region: String, summary: String, checksum: String, active: Bool, segment: String, rate: Double, status: GlobalIsolationRequestStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.region = region
            self.summary = summary
            self.checksum = checksum
            self.active = active
            self.segment = segment
            self.rate = rate
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

        func canMoveTo(_ next: GlobalIsolationRequestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalIsolationRequestStatus.cancelled
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

        func moveTo(_ next: GlobalIsolationRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global isolation request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> GlobalIsolationRequest {
            return GlobalIsolationRequest(
                code: code,
                title: title,
                source: source,
                region: region,
                summary: summary,
                checksum: checksum,
                active: active,
                segment: segment,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global isolation request in status planned.
    static func newGlobalIsolationRequest(_ code: String, title: String) -> GlobalIsolationRequest {
        return GlobalIsolationRequest(
            code: code,
            title: title,
            source: "",
            region: "",
            summary: "",
            checksum: "",
            active: false,
            segment: "",
            rate: 0.0,
            status: GlobalIsolationRequestStatus.planned
        )
    }
}
