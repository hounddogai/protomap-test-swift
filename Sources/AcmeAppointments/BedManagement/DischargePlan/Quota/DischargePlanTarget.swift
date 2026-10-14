import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan target is in its life cycle.
    enum DischargePlanTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A discharge plan target as the discharge plan team keeps it.
    final class DischargePlanTarget {
        var code: String
        var name: String
        var margin: Double
        var facility: String
        var region: String
        var ceiling: Double
        var status: DischargePlanTargetStatus

        init(code: String, name: String, margin: Double, facility: String, region: String, ceiling: Double, status: DischargePlanTargetStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.facility = facility
            self.region = region
            self.ceiling = ceiling
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

        func canMoveTo(_ next: DischargePlanTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DischargePlanTargetStatus.resolved || next == DischargePlanTargetStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DischargePlanTargetStatus.archived
            case .reopened:
                return next == DischargePlanTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return (margin * ceiling * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanTarget {
            return DischargePlanTarget(
                code: code,
                name: name,
                margin: margin,
                facility: facility,
                region: region,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a discharge plan target in status open.
    static func newDischargePlanTarget(_ code: String, name: String) -> DischargePlanTarget {
        return DischargePlanTarget(
            code: code,
            name: name,
            margin: 0.0,
            facility: "",
            region: "",
            ceiling: 0.0,
            status: DischargePlanTargetStatus.`open`
        )
    }
}
