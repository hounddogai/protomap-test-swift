import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped discharge plan item is in its life cycle.
    enum CappedDischargePlanItemStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped discharge plan item and its current status.
    final class CappedDischargePlanItem {
        var code: String
        var name: String
        var region: String
        var reviewer: String
        var patientRef: String
        var facility: String
        var quantity: Int
        var status: CappedDischargePlanItemStatus

        init(code: String, name: String, region: String, reviewer: String, patientRef: String, facility: String, quantity: Int, status: CappedDischargePlanItemStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.facility = facility
            self.quantity = quantity
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

        func canMoveTo(_ next: CappedDischargePlanItemStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedDischargePlanItemStatus.reopened || next == CappedDischargePlanItemStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CappedDischargePlanItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped discharge plan item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CappedDischargePlanItem {
            return CappedDischargePlanItem(
                code: code,
                name: name,
                region: region,
                reviewer: reviewer,
                patientRef: patientRef,
                facility: facility,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped discharge plan item in status open.
    static func newCappedDischargePlanItem(_ code: String, name: String) -> CappedDischargePlanItem {
        return CappedDischargePlanItem(
            code: code,
            name: name,
            region: "",
            reviewer: "",
            patientRef: "",
            facility: "",
            quantity: 0,
            status: CappedDischargePlanItemStatus.`open`
        )
    }
}
