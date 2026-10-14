import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped order set rollup is in its life cycle.
    enum CappedOrderSetRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped order set rollup as the order set team keeps it.
    final class CappedOrderSetRollup {
        var code: String
        var label: String
        var facility: String
        var tags: [String]
        var updatedAt: Int
        var timezone: String
        var minimum: Double
        var reviewer: String
        var status: CappedOrderSetRollupStatus

        init(code: String, label: String, facility: String, tags: [String], updatedAt: Int, timezone: String, minimum: Double, reviewer: String, status: CappedOrderSetRollupStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.tags = tags
            self.updatedAt = updatedAt
            self.timezone = timezone
            self.minimum = minimum
            self.reviewer = reviewer
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

        func canMoveTo(_ next: CappedOrderSetRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CappedOrderSetRollupStatus.draining || next == CappedOrderSetRollupStatus.stopped
            case .draining:
                return next == CappedOrderSetRollupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedOrderSetRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped order set rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("capped order set rollup") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return (minimum * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedOrderSetRollup {
            return CappedOrderSetRollup(
                code: code,
                label: label,
                facility: facility,
                tags: tags,
                updatedAt: updatedAt,
                timezone: timezone,
                minimum: minimum,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped order set rollup in status idle.
    static func newCappedOrderSetRollup(_ code: String, label: String) -> CappedOrderSetRollup {
        return CappedOrderSetRollup(
            code: code,
            label: label,
            facility: "",
            tags: [],
            updatedAt: 0,
            timezone: "",
            minimum: 0.0,
            reviewer: "",
            status: CappedOrderSetRollupStatus.idle
        )
    }
}
