import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap batch is in its life cycle.
    enum CareGapBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A care gap batch as the care gap team keeps it.
    final class CareGapBatch {
        var code: String
        var name: String
        var threshold: Double
        var region: String
        var revision: Int
        var status: CareGapBatchStatus

        init(code: String, name: String, threshold: Double, region: String, revision: Int, status: CareGapBatchStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.region = region
            self.revision = revision
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

        func canMoveTo(_ next: CareGapBatchStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CareGapBatchStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CareGapBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("care gap batch") \(code)"
        }

        func projectedExposure() -> Double {
            return (threshold * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> CareGapBatch {
            return CareGapBatch(
                code: code,
                name: name,
                threshold: threshold,
                region: region,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care gap batch in status requested.
    static func newCareGapBatch(_ code: String, name: String) -> CareGapBatch {
        return CareGapBatch(
            code: code,
            name: name,
            threshold: 0.0,
            region: "",
            revision: 0,
            status: CareGapBatchStatus.requested
        )
    }
}
