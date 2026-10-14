import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction estimate is in its life cycle.
    enum InteractionEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A interaction estimate. Its code is unique within a tenant.
    final class InteractionEstimate {
        var code: String
        var label: String
        var bed: String
        var limit: Int
        var specialty: String
        var threshold: Double
        var reviewer: String
        var expiresAt: Int
        var updatedAt: Int
        var revision: Int
        var status: InteractionEstimateStatus

        init(code: String, label: String, bed: String, limit: Int, specialty: String, threshold: Double, reviewer: String, expiresAt: Int, updatedAt: Int, revision: Int, status: InteractionEstimateStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.limit = limit
            self.specialty = specialty
            self.threshold = threshold
            self.reviewer = reviewer
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.revision = revision
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

        func canMoveTo(_ next: InteractionEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == InteractionEstimateStatus.queued
            case .queued:
                return next == InteractionEstimateStatus.done
            case .running:
                return next == InteractionEstimateStatus.done
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

        func moveTo(_ next: InteractionEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedExposure() -> Double {
            return ((Double(updatedAt) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionEstimate {
            return InteractionEstimate(
                code: code,
                label: label,
                bed: bed,
                limit: limit,
                specialty: specialty,
                threshold: threshold,
                reviewer: reviewer,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a interaction estimate in status new.
    static func newInteractionEstimate(_ code: String, label: String) -> InteractionEstimate {
        return InteractionEstimate(
            code: code,
            label: label,
            bed: "",
            limit: 0,
            specialty: "",
            threshold: 0.0,
            reviewer: "",
            expiresAt: 0,
            updatedAt: 0,
            revision: 0,
            status: InteractionEstimateStatus.new
        )
    }
}
