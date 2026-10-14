import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall estimate is in its life cycle.
    enum RecallEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A recall estimate. Its code is unique within a tenant.
    final class RecallEstimate {
        var code: String
        var title: String
        var rate: Double
        var updatedAt: Int
        var threshold: Double
        var archived: Bool
        var batchSize: Int
        var status: RecallEstimateStatus

        init(code: String, title: String, rate: Double, updatedAt: Int, threshold: Double, archived: Bool, batchSize: Int, status: RecallEstimateStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.archived = archived
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RecallEstimateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RecallEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((Double(batchSize) + rate) * 100).rounded() / 100
        }

        func copyValue() -> RecallEstimate {
            return RecallEstimate(
                code: code,
                title: title,
                rate: rate,
                updatedAt: updatedAt,
                threshold: threshold,
                archived: archived,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a recall estimate in status new.
    static func newRecallEstimate(_ code: String, title: String) -> RecallEstimate {
        return RecallEstimate(
            code: code,
            title: title,
            rate: 0.0,
            updatedAt: 0,
            threshold: 0.0,
            archived: false,
            batchSize: 0,
            status: RecallEstimateStatus.new
        )
    }
}
