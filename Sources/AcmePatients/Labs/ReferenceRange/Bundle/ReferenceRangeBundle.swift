import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range bundle is in its life cycle.
    enum ReferenceRangeBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One reference range bundle, with what the planners need to act on it.
    final class ReferenceRangeBundle {
        var code: String
        var label: String
        var limit: Int
        var region: String
        var pinned: Bool
        var status: ReferenceRangeBundleStatus

        init(code: String, label: String, limit: Int, region: String, pinned: Bool, status: ReferenceRangeBundleStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.region = region
            self.pinned = pinned
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

        func canMoveTo(_ next: ReferenceRangeBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ReferenceRangeBundleStatus.ready || next == ReferenceRangeBundleStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ReferenceRangeBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("reference range bundle") \(code)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> ReferenceRangeBundle {
            return ReferenceRangeBundle(
                code: code,
                label: label,
                limit: limit,
                region: region,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a reference range bundle in status idle.
    static func newReferenceRangeBundle(_ code: String, label: String) -> ReferenceRangeBundle {
        return ReferenceRangeBundle(
            code: code,
            label: label,
            limit: 0,
            region: "",
            pinned: false,
            status: ReferenceRangeBundleStatus.idle
        )
    }
}
