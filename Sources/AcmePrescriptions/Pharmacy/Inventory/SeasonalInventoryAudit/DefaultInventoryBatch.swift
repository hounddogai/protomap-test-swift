import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default inventory batch is in its life cycle.
    enum DefaultInventoryBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A default inventory batch. Its code is unique within a tenant.
    final class DefaultInventoryBatch {
        var code: String
        var title: String
        var procedureCode: String
        var active: Bool
        var name: String
        var score: Double
        var status: DefaultInventoryBatchStatus

        init(code: String, title: String, procedureCode: String, active: Bool, name: String, score: Double, status: DefaultInventoryBatchStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.active = active
            self.name = name
            self.score = score
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

        func canMoveTo(_ next: DefaultInventoryBatchStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == DefaultInventoryBatchStatus.active || next == DefaultInventoryBatchStatus.closed
            case .active:
                return next == DefaultInventoryBatchStatus.suspended
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

        func moveTo(_ next: DefaultInventoryBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default inventory batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> DefaultInventoryBatch {
            return DefaultInventoryBatch(
                code: code,
                title: title,
                procedureCode: procedureCode,
                active: active,
                name: name,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default inventory batch in status draft.
    static func newDefaultInventoryBatch(_ code: String, title: String) -> DefaultInventoryBatch {
        return DefaultInventoryBatch(
            code: code,
            title: title,
            procedureCode: "",
            active: false,
            name: "",
            score: 0.0,
            status: DefaultInventoryBatchStatus.draft
        )
    }
}
