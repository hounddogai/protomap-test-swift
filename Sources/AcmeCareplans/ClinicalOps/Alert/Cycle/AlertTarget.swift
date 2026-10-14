import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert target is in its life cycle.
    enum AlertTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A alert target as the alert team keeps it.
    final class AlertTarget {
        var code: String
        var label: String
        var diagnosisCode: String
        var discount: Double
        var capacity: Int
        var ratio: Double
        var cost: Double
        var visible: Bool
        var clinicianID: String
        var margin: Double
        var unit: String
        var status: AlertTargetStatus

        init(code: String, label: String, diagnosisCode: String, discount: Double, capacity: Int, ratio: Double, cost: Double, visible: Bool, clinicianID: String, margin: Double, unit: String, status: AlertTargetStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.discount = discount
            self.capacity = capacity
            self.ratio = ratio
            self.cost = cost
            self.visible = visible
            self.clinicianID = clinicianID
            self.margin = margin
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertTargetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AlertTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedVolume() -> Double {
            return ((margin + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AlertTarget {
            return AlertTarget(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                discount: discount,
                capacity: capacity,
                ratio: ratio,
                cost: cost,
                visible: visible,
                clinicianID: clinicianID,
                margin: margin,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a alert target in status draft.
    static func newAlertTarget(_ code: String, label: String) -> AlertTarget {
        return AlertTarget(
            code: code,
            label: label,
            diagnosisCode: "",
            discount: 0.0,
            capacity: 0,
            ratio: 0.0,
            cost: 0.0,
            visible: false,
            clinicianID: "",
            margin: 0.0,
            unit: "",
            status: AlertTargetStatus.draft
        )
    }
}
