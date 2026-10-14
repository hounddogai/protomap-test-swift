import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict shift threshold is in its life cycle.
    enum StrictShiftThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict shift threshold as the shift team keeps it.
    final class StrictShiftThreshold {
        var code: String
        var label: String
        var cost: Double
        var visitMinutes: Int
        var ward: String
        var unit: String
        var visible: Bool
        var priority: Int
        var retries: Int
        var name: String
        var checksum: String
        var status: StrictShiftThresholdStatus

        init(code: String, label: String, cost: Double, visitMinutes: Int, ward: String, unit: String, visible: Bool, priority: Int, retries: Int, name: String, checksum: String, status: StrictShiftThresholdStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.visitMinutes = visitMinutes
            self.ward = ward
            self.unit = unit
            self.visible = visible
            self.priority = priority
            self.retries = retries
            self.name = name
            self.checksum = checksum
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

        func canMoveTo(_ next: StrictShiftThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictShiftThresholdStatus.inReview || next == StrictShiftThresholdStatus.archived
            case .inReview:
                return next == StrictShiftThresholdStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StrictShiftThresholdStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictShiftThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict shift threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(visitMinutes) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> StrictShiftThreshold {
            return StrictShiftThreshold(
                code: code,
                label: label,
                cost: cost,
                visitMinutes: visitMinutes,
                ward: ward,
                unit: unit,
                visible: visible,
                priority: priority,
                retries: retries,
                name: name,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict shift threshold in status open.
    static func newStrictShiftThreshold(_ code: String, label: String) -> StrictShiftThreshold {
        return StrictShiftThreshold(
            code: code,
            label: label,
            cost: 0.0,
            visitMinutes: 0,
            ward: "",
            unit: "",
            visible: false,
            priority: 0,
            retries: 0,
            name: "",
            checksum: "",
            status: StrictShiftThresholdStatus.`open`
        )
    }
}
