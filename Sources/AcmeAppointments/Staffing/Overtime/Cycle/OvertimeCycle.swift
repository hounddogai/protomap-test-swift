import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime cycle is in its life cycle.
    enum OvertimeCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A overtime cycle. Its code is unique within a tenant.
    final class OvertimeCycle {
        var code: String
        var label: String
        var allergy: String
        var pinned: Bool
        var reviewer: String
        var tags: [String]
        var maximum: Double
        var graceDays: Int
        var status: OvertimeCycleStatus

        init(code: String, label: String, allergy: String, pinned: Bool, reviewer: String, tags: [String], maximum: Double, graceDays: Int, status: OvertimeCycleStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.pinned = pinned
            self.reviewer = reviewer
            self.tags = tags
            self.maximum = maximum
            self.graceDays = graceDays
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

        func canMoveTo(_ next: OvertimeCycleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == OvertimeCycleStatus.draining || next == OvertimeCycleStatus.stopped
            case .draining:
                return next == OvertimeCycleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return ((maximum - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeCycle {
            return OvertimeCycle(
                code: code,
                label: label,
                allergy: allergy,
                pinned: pinned,
                reviewer: reviewer,
                tags: tags,
                maximum: maximum,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a overtime cycle in status idle.
    static func newOvertimeCycle(_ code: String, label: String) -> OvertimeCycle {
        return OvertimeCycle(
            code: code,
            label: label,
            allergy: "",
            pinned: false,
            reviewer: "",
            tags: [],
            maximum: 0.0,
            graceDays: 0,
            status: OvertimeCycleStatus.idle
        )
    }
}
