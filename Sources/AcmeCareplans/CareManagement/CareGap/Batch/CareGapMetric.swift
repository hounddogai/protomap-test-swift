import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap metric is in its life cycle.
    enum CareGapMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One care gap metric, with what the planners need to act on it.
    final class CareGapMetric {
        var code: String
        var title: String
        var batchSize: Int
        var archived: Bool
        var sequence: Int
        var floorValue: Double
        var status: CareGapMetricStatus

        init(code: String, title: String, batchSize: Int, archived: Bool, sequence: Int, floorValue: Double, status: CareGapMetricStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.archived = archived
            self.sequence = sequence
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CareGapMetricStatus.revoked
            case .revoked:
                return next == CareGapMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return ((Double(batchSize) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapMetric {
            return CareGapMetric(
                code: code,
                title: title,
                batchSize: batchSize,
                archived: archived,
                sequence: sequence,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care gap metric in status requested.
    static func newCareGapMetric(_ code: String, title: String) -> CareGapMetric {
        return CareGapMetric(
            code: code,
            title: title,
            batchSize: 0,
            archived: false,
            sequence: 0,
            floorValue: 0.0,
            status: CareGapMetricStatus.requested
        )
    }
}
