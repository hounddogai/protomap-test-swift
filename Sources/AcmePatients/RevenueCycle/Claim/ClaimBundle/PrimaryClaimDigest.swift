import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary claim digest is in its life cycle.
    enum PrimaryClaimDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary claim digest as the claim team keeps it.
    final class PrimaryClaimDigest {
        var code: String
        var title: String
        var specialty: String
        var threshold: Double
        var revision: Int
        var createdAt: Int
        var refills: Int
        var visitMinutes: Int
        var ceiling: Double
        var diagnosisCode: String
        var quantity: Int
        var status: PrimaryClaimDigestStatus

        init(code: String, title: String, specialty: String, threshold: Double, revision: Int, createdAt: Int, refills: Int, visitMinutes: Int, ceiling: Double, diagnosisCode: String, quantity: Int, status: PrimaryClaimDigestStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.threshold = threshold
            self.revision = revision
            self.createdAt = createdAt
            self.refills = refills
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
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

        func canMoveTo(_ next: PrimaryClaimDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PrimaryClaimDigestStatus.running
            case .running:
                return next == PrimaryClaimDigestStatus.failed
            case .done:
                return next == PrimaryClaimDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryClaimDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary claim digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((threshold + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryClaimDigest {
            return PrimaryClaimDigest(
                code: code,
                title: title,
                specialty: specialty,
                threshold: threshold,
                revision: revision,
                createdAt: createdAt,
                refills: refills,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary claim digest in status new.
    static func newPrimaryClaimDigest(_ code: String, title: String) -> PrimaryClaimDigest {
        return PrimaryClaimDigest(
            code: code,
            title: title,
            specialty: "",
            threshold: 0.0,
            revision: 0,
            createdAt: 0,
            refills: 0,
            visitMinutes: 0,
            ceiling: 0.0,
            diagnosisCode: "",
            quantity: 0,
            status: PrimaryClaimDigestStatus.new
        )
    }
}
