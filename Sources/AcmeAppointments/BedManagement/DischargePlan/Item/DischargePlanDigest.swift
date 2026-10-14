import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan digest is in its life cycle.
    enum DischargePlanDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a discharge plan digest and its current status.
    final class DischargePlanDigest {
        var code: String
        var title: String
        var cost: Double
        var summary: String
        var margin: Double
        var floorValue: Double
        var minimum: Double
        var active: Bool
        var status: DischargePlanDigestStatus

        init(code: String, title: String, cost: Double, summary: String, margin: Double, floorValue: Double, minimum: Double, active: Bool, status: DischargePlanDigestStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.summary = summary
            self.margin = margin
            self.floorValue = floorValue
            self.minimum = minimum
            self.active = active
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

        func canMoveTo(_ next: DischargePlanDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == DischargePlanDigestStatus.stopped
            case .warming:
                return next == DischargePlanDigestStatus.stopped
            case .ready:
                return next == DischargePlanDigestStatus.stopped
            case .draining:
                return next == DischargePlanDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return ((floorValue + cost) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanDigest {
            return DischargePlanDigest(
                code: code,
                title: title,
                cost: cost,
                summary: summary,
                margin: margin,
                floorValue: floorValue,
                minimum: minimum,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan digest in status idle.
    static func newDischargePlanDigest(_ code: String, title: String) -> DischargePlanDigest {
        return DischargePlanDigest(
            code: code,
            title: title,
            cost: 0.0,
            summary: "",
            margin: 0.0,
            floorValue: 0.0,
            minimum: 0.0,
            active: false,
            status: DischargePlanDigestStatus.idle
        )
    }
}
