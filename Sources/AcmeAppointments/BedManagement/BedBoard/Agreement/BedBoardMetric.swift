import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board metric is in its life cycle.
    enum BedBoardMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A bed board metric. Its code is unique within a tenant.
    final class BedBoardMetric {
        var code: String
        var name: String
        var visible: Bool
        var amount: Double
        var diagnosisCode: String
        var label: String
        var updatedAt: Int
        var status: BedBoardMetricStatus

        init(code: String, name: String, visible: Bool, amount: Double, diagnosisCode: String, label: String, updatedAt: Int, status: BedBoardMetricStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.amount = amount
            self.diagnosisCode = diagnosisCode
            self.label = label
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: BedBoardMetricStatus) -> Bool {
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
                case .suspended:
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
                switch next {
                case .closed:
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

        func moveTo(_ next: BedBoardMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("bed board metric") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(updatedAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardMetric {
            return BedBoardMetric(
                code: code,
                name: name,
                visible: visible,
                amount: amount,
                diagnosisCode: diagnosisCode,
                label: label,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a bed board metric in status draft.
    static func newBedBoardMetric(_ code: String, name: String) -> BedBoardMetric {
        return BedBoardMetric(
            code: code,
            name: name,
            visible: false,
            amount: 0.0,
            diagnosisCode: "",
            label: "",
            updatedAt: 0,
            status: BedBoardMetricStatus.draft
        )
    }
}
