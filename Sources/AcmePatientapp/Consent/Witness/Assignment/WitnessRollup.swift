import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness rollup is in its life cycle.
    enum WitnessRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A witness rollup. Its code is unique within a tenant.
    final class WitnessRollup {
        var code: String
        var title: String
        var quantity: Int
        var allergy: String
        var revision: Int
        var status: WitnessRollupStatus

        init(code: String, title: String, quantity: Int, allergy: String, revision: Int, status: WitnessRollupStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.allergy = allergy
            self.revision = revision
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

        func canMoveTo(_ next: WitnessRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == WitnessRollupStatus.active || next == WitnessRollupStatus.suspended
            case .pending:
                switch next {
                case .closed:
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

        func moveTo(_ next: WitnessRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("witness rollup") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(revision) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessRollup {
            return WitnessRollup(
                code: code,
                title: title,
                quantity: quantity,
                allergy: allergy,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a witness rollup in status draft.
    static func newWitnessRollup(_ code: String, title: String) -> WitnessRollup {
        return WitnessRollup(
            code: code,
            title: title,
            quantity: 0,
            allergy: "",
            revision: 0,
            status: WitnessRollupStatus.draft
        )
    }
}
