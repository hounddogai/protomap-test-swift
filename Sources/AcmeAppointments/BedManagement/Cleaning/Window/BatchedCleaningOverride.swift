import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched cleaning override is in its life cycle.
    enum BatchedCleaningOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched cleaning override. Its code is unique within a tenant.
    final class BatchedCleaningOverride {
        var code: String
        var title: String
        var approved: Bool
        var diagnosisCode: String
        var pinned: Bool
        var segment: String
        var windowDays: Int
        var status: BatchedCleaningOverrideStatus

        init(code: String, title: String, approved: Bool, diagnosisCode: String, pinned: Bool, segment: String, windowDays: Int, status: BatchedCleaningOverrideStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.pinned = pinned
            self.segment = segment
            self.windowDays = windowDays
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

        func canMoveTo(_ next: BatchedCleaningOverrideStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == BatchedCleaningOverrideStatus.done
            case .done:
                return next == BatchedCleaningOverrideStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCleaningOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched cleaning override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched cleaning override") \(code)"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> BatchedCleaningOverride {
            return BatchedCleaningOverride(
                code: code,
                title: title,
                approved: approved,
                diagnosisCode: diagnosisCode,
                pinned: pinned,
                segment: segment,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched cleaning override in status new.
    static func newBatchedCleaningOverride(_ code: String, title: String) -> BatchedCleaningOverride {
        return BatchedCleaningOverride(
            code: code,
            title: title,
            approved: false,
            diagnosisCode: "",
            pinned: false,
            segment: "",
            windowDays: 0,
            status: BatchedCleaningOverrideStatus.new
        )
    }
}
