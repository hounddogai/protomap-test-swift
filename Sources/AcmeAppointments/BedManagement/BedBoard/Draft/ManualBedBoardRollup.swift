import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual bed board rollup is in its life cycle.
    enum ManualBedBoardRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One manual bed board rollup, with what the planners need to act on it.
    final class ManualBedBoardRollup {
        var code: String
        var label: String
        var limit: Int
        var budget: Double
        var contactEmail: String
        var amount: Double
        var patientRef: String
        var status: ManualBedBoardRollupStatus

        init(code: String, label: String, limit: Int, budget: Double, contactEmail: String, amount: Double, patientRef: String, status: ManualBedBoardRollupStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.budget = budget
            self.contactEmail = contactEmail
            self.amount = amount
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualBedBoardRollupStatus) -> Bool {
            switch status {
            case .idle:
                return next == ManualBedBoardRollupStatus.warming || next == ManualBedBoardRollupStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ManualBedBoardRollupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualBedBoardRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual bed board rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual bed board rollup") \(code)"
        }

        func netTotal() -> Double {
            return ((amount + budget) * 100).rounded() / 100
        }

        func copyValue() -> ManualBedBoardRollup {
            return ManualBedBoardRollup(
                code: code,
                label: label,
                limit: limit,
                budget: budget,
                contactEmail: contactEmail,
                amount: amount,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual bed board rollup in status idle.
    static func newManualBedBoardRollup(_ code: String, label: String) -> ManualBedBoardRollup {
        return ManualBedBoardRollup(
            code: code,
            label: label,
            limit: 0,
            budget: 0.0,
            contactEmail: "",
            amount: 0.0,
            patientRef: "",
            status: ManualBedBoardRollupStatus.idle
        )
    }
}
