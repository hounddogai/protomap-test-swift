import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory batch is in its life cycle.
    enum InventoryBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A inventory batch as the inventory team keeps it.
    final class InventoryBatch {
        var code: String
        var title: String
        var facility: String
        var payer: String
        var cost: Double
        var summary: String
        var budget: Double
        var source: String
        var ratio: Double
        var procedureCode: String
        var status: InventoryBatchStatus

        init(code: String, title: String, facility: String, payer: String, cost: Double, summary: String, budget: Double, source: String, ratio: Double, procedureCode: String, status: InventoryBatchStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.payer = payer
            self.cost = cost
            self.summary = summary
            self.budget = budget
            self.source = source
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryBatchStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == InventoryBatchStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((budget + ratio) * 100).rounded() / 100
        }

        func copyValue() -> InventoryBatch {
            return InventoryBatch(
                code: code,
                title: title,
                facility: facility,
                payer: payer,
                cost: cost,
                summary: summary,
                budget: budget,
                source: source,
                ratio: ratio,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a inventory batch in status created.
    static func newInventoryBatch(_ code: String, title: String) -> InventoryBatch {
        return InventoryBatch(
            code: code,
            title: title,
            facility: "",
            payer: "",
            cost: 0.0,
            summary: "",
            budget: 0.0,
            source: "",
            ratio: 0.0,
            procedureCode: "",
            status: InventoryBatchStatus.created
        )
    }
}
