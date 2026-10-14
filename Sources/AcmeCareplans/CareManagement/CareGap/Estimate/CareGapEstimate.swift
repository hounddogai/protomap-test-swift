import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap estimate is in its life cycle.
    enum CareGapEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One care gap estimate, with what the planners need to act on it.
    final class CareGapEstimate {
        var code: String
        var label: String
        var unit: String
        var windowDays: Int
        var createdAt: Int
        var status: CareGapEstimateStatus

        init(code: String, label: String, unit: String, windowDays: Int, createdAt: Int, status: CareGapEstimateStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.windowDays = windowDays
            self.createdAt = createdAt
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

        func canMoveTo(_ next: CareGapEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CareGapEstimateStatus.reopened || next == CareGapEstimateStatus.archived
            case .resolved:
                return next == CareGapEstimateStatus.archived
            case .reopened:
                return next == CareGapEstimateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("care gap estimate") \(code)"
        }

        func netTotal() -> Double {
            return (Double(createdAt) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> CareGapEstimate {
            return CareGapEstimate(
                code: code,
                label: label,
                unit: unit,
                windowDays: windowDays,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a care gap estimate in status open.
    static func newCareGapEstimate(_ code: String, label: String) -> CareGapEstimate {
        return CareGapEstimate(
            code: code,
            label: label,
            unit: "",
            windowDays: 0,
            createdAt: 0,
            status: CareGapEstimateStatus.`open`
        )
    }
}
