import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled network bundle is in its life cycle.
    enum ScheduledNetworkBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a scheduled network bundle and its current status.
    final class ScheduledNetworkBundle {
        var code: String
        var label: String
        var tags: [String]
        var windowDays: Int
        var phone: String
        var threshold: Double
        var floorValue: Double
        var bed: String
        var pinned: Bool
        var status: ScheduledNetworkBundleStatus

        init(code: String, label: String, tags: [String], windowDays: Int, phone: String, threshold: Double, floorValue: Double, bed: String, pinned: Bool, status: ScheduledNetworkBundleStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.windowDays = windowDays
            self.phone = phone
            self.threshold = threshold
            self.floorValue = floorValue
            self.bed = bed
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

        func canMoveTo(_ next: ScheduledNetworkBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledNetworkBundleStatus.draining
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ScheduledNetworkBundleStatus.draining || next == ScheduledNetworkBundleStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledNetworkBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled network bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedExposure() -> Double {
            return ((Double(windowDays) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledNetworkBundle {
            return ScheduledNetworkBundle(
                code: code,
                label: label,
                tags: tags,
                windowDays: windowDays,
                phone: phone,
                threshold: threshold,
                floorValue: floorValue,
                bed: bed,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled network bundle in status idle.
    static func newScheduledNetworkBundle(_ code: String, label: String) -> ScheduledNetworkBundle {
        return ScheduledNetworkBundle(
            code: code,
            label: label,
            tags: [],
            windowDays: 0,
            phone: "",
            threshold: 0.0,
            floorValue: 0.0,
            bed: "",
            pinned: false,
            status: ScheduledNetworkBundleStatus.idle
        )
    }
}
