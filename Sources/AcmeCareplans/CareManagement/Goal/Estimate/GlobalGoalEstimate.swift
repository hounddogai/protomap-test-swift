import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global goal estimate is in its life cycle.
    enum GlobalGoalEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global goal estimate as the goal team keeps it.
    final class GlobalGoalEstimate {
        var code: String
        var name: String
        var archived: Bool
        var source: String
        var visible: Bool
        var checksum: String
        var clinicianID: String
        var amount: Double
        var status: GlobalGoalEstimateStatus

        init(code: String, name: String, archived: Bool, source: String, visible: Bool, checksum: String, clinicianID: String, amount: Double, status: GlobalGoalEstimateStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.source = source
            self.visible = visible
            self.checksum = checksum
            self.clinicianID = clinicianID
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalGoalEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalGoalEstimateStatus.running || next == GlobalGoalEstimateStatus.failed
            case .queued:
                return next == GlobalGoalEstimateStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GlobalGoalEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalGoalEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global goal estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global goal estimate") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> GlobalGoalEstimate {
            return GlobalGoalEstimate(
                code: code,
                name: name,
                archived: archived,
                source: source,
                visible: visible,
                checksum: checksum,
                clinicianID: clinicianID,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global goal estimate in status new.
    static func newGlobalGoalEstimate(_ code: String, name: String) -> GlobalGoalEstimate {
        return GlobalGoalEstimate(
            code: code,
            name: name,
            archived: false,
            source: "",
            visible: false,
            checksum: "",
            clinicianID: "",
            amount: 0.0,
            status: GlobalGoalEstimateStatus.new
        )
    }
}
