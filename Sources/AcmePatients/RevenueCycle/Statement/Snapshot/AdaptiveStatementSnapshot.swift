import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive statement snapshot is in its life cycle.
    enum AdaptiveStatementSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive statement snapshot as the statement team keeps it.
    final class AdaptiveStatementSnapshot {
        var code: String
        var name: String
        var quantity: Int
        var checksum: String
        var label: String
        var pinned: Bool
        var procedureCode: String
        var allergy: String
        var status: AdaptiveStatementSnapshotStatus

        init(code: String, name: String, quantity: Int, checksum: String, label: String, pinned: Bool, procedureCode: String, allergy: String, status: AdaptiveStatementSnapshotStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.checksum = checksum
            self.label = label
            self.pinned = pinned
            self.procedureCode = procedureCode
            self.allergy = allergy
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

        func canMoveTo(_ next: AdaptiveStatementSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveStatementSnapshotStatus.inReview || next == AdaptiveStatementSnapshotStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AdaptiveStatementSnapshotStatus.reopened
            case .reopened:
                return next == AdaptiveStatementSnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveStatementSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive statement snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive statement snapshot") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> AdaptiveStatementSnapshot {
            return AdaptiveStatementSnapshot(
                code: code,
                name: name,
                quantity: quantity,
                checksum: checksum,
                label: label,
                pinned: pinned,
                procedureCode: procedureCode,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive statement snapshot in status open.
    static func newAdaptiveStatementSnapshot(_ code: String, name: String) -> AdaptiveStatementSnapshot {
        return AdaptiveStatementSnapshot(
            code: code,
            name: name,
            quantity: 0,
            checksum: "",
            label: "",
            pinned: false,
            procedureCode: "",
            allergy: "",
            status: AdaptiveStatementSnapshotStatus.`open`
        )
    }
}
