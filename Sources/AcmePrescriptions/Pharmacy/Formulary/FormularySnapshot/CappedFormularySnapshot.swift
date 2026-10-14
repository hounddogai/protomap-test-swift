import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped formulary snapshot is in its life cycle.
    enum CappedFormularySnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One capped formulary snapshot, with what the planners need to act on it.
    final class CappedFormularySnapshot {
        var code: String
        var name: String
        var cost: Double
        var discount: Double
        var externalRef: String
        var status: CappedFormularySnapshotStatus

        init(code: String, name: String, cost: Double, discount: Double, externalRef: String, status: CappedFormularySnapshotStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.discount = discount
            self.externalRef = externalRef
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

        func canMoveTo(_ next: CappedFormularySnapshotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CappedFormularySnapshotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedFormularySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped formulary snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped formulary snapshot") \(code)"
        }

        func netLoad() -> Double {
            return (cost * discount * 100).rounded() / 100
        }

        func copyValue() -> CappedFormularySnapshot {
            return CappedFormularySnapshot(
                code: code,
                name: name,
                cost: cost,
                discount: discount,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped formulary snapshot in status draft.
    static func newCappedFormularySnapshot(_ code: String, name: String) -> CappedFormularySnapshot {
        return CappedFormularySnapshot(
            code: code,
            name: name,
            cost: 0.0,
            discount: 0.0,
            externalRef: "",
            status: CappedFormularySnapshotStatus.draft
        )
    }
}
