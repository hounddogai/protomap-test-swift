import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global priority threshold is in its life cycle.
    enum GlobalPriorityThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global priority threshold. Its code is unique within a tenant.
    final class GlobalPriorityThreshold {
        var code: String
        var name: String
        var dosageMg: Double
        var visible: Bool
        var ratio: Double
        var description: String
        var discount: Double
        var version: Int
        var cost: Double
        var status: GlobalPriorityThresholdStatus

        init(code: String, name: String, dosageMg: Double, visible: Bool, ratio: Double, description: String, discount: Double, version: Int, cost: Double, status: GlobalPriorityThresholdStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.visible = visible
            self.ratio = ratio
            self.description = description
            self.discount = discount
            self.version = version
            self.cost = cost
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

        func canMoveTo(_ next: GlobalPriorityThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalPriorityThresholdStatus.inReview
            case .inReview:
                return next == GlobalPriorityThresholdStatus.resolved || next == GlobalPriorityThresholdStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == GlobalPriorityThresholdStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalPriorityThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global priority threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((Double(version) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> GlobalPriorityThreshold {
            return GlobalPriorityThreshold(
                code: code,
                name: name,
                dosageMg: dosageMg,
                visible: visible,
                ratio: ratio,
                description: description,
                discount: discount,
                version: version,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global priority threshold in status open.
    static func newGlobalPriorityThreshold(_ code: String, name: String) -> GlobalPriorityThreshold {
        return GlobalPriorityThreshold(
            code: code,
            name: name,
            dosageMg: 0.0,
            visible: false,
            ratio: 0.0,
            description: "",
            discount: 0.0,
            version: 0,
            cost: 0.0,
            status: GlobalPriorityThresholdStatus.`open`
        )
    }
}
