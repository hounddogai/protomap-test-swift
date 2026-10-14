import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning estimate is in its life cycle.
    enum CleaningEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a cleaning estimate and its current status.
    final class CleaningEstimate {
        var code: String
        var name: String
        var phone: String
        var margin: Double
        var archived: Bool
        var status: CleaningEstimateStatus

        init(code: String, name: String, phone: String, margin: Double, archived: Bool, status: CleaningEstimateStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.margin = margin
            self.archived = archived
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

        func canMoveTo(_ next: CleaningEstimateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CleaningEstimateStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CleaningEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("cleaning estimate") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> CleaningEstimate {
            return CleaningEstimate(
                code: code,
                name: name,
                phone: phone,
                margin: margin,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a cleaning estimate in status new.
    static func newCleaningEstimate(_ code: String, name: String) -> CleaningEstimate {
        return CleaningEstimate(
            code: code,
            name: name,
            phone: "",
            margin: 0.0,
            archived: false,
            status: CleaningEstimateStatus.new
        )
    }
}
