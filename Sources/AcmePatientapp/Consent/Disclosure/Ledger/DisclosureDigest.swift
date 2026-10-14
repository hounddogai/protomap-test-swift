import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure digest is in its life cycle.
    enum DisclosureDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a disclosure digest and its current status.
    final class DisclosureDigest {
        var code: String
        var label: String
        var title: String
        var approved: Bool
        var rate: Double
        var externalRef: String
        var discount: Double
        var visible: Bool
        var score: Double
        var cost: Double
        var floorValue: Double
        var status: DisclosureDigestStatus

        init(code: String, label: String, title: String, approved: Bool, rate: Double, externalRef: String, discount: Double, visible: Bool, score: Double, cost: Double, floorValue: Double, status: DisclosureDigestStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.approved = approved
            self.rate = rate
            self.externalRef = externalRef
            self.discount = discount
            self.visible = visible
            self.score = score
            self.cost = cost
            self.floorValue = floorValue
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

        func canMoveTo(_ next: DisclosureDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == DisclosureDigestStatus.cancelled
            case .scheduled:
                return next == DisclosureDigestStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DisclosureDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return (floorValue * cost * 100).rounded() / 100
        }

        func copyValue() -> DisclosureDigest {
            return DisclosureDigest(
                code: code,
                label: label,
                title: title,
                approved: approved,
                rate: rate,
                externalRef: externalRef,
                discount: discount,
                visible: visible,
                score: score,
                cost: cost,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure digest in status planned.
    static func newDisclosureDigest(_ code: String, label: String) -> DisclosureDigest {
        return DisclosureDigest(
            code: code,
            label: label,
            title: "",
            approved: false,
            rate: 0.0,
            externalRef: "",
            discount: 0.0,
            visible: false,
            score: 0.0,
            cost: 0.0,
            floorValue: 0.0,
            status: DisclosureDigestStatus.planned
        )
    }
}
