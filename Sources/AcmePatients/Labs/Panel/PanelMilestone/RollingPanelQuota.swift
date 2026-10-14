import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling panel quota is in its life cycle.
    enum RollingPanelQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling panel quota. Its code is unique within a tenant.
    final class RollingPanelQuota {
        var code: String
        var title: String
        var threshold: Double
        var specialty: String
        var updatedAt: Int
        var allergy: String
        var attempts: Int
        var clinicianID: String
        var region: String
        var summary: String
        var status: RollingPanelQuotaStatus

        init(code: String, title: String, threshold: Double, specialty: String, updatedAt: Int, allergy: String, attempts: Int, clinicianID: String, region: String, summary: String, status: RollingPanelQuotaStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.allergy = allergy
            self.attempts = attempts
            self.clinicianID = clinicianID
            self.region = region
            self.summary = summary
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

        func canMoveTo(_ next: RollingPanelQuotaStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingPanelQuotaStatus.done
            case .queued:
                return next == RollingPanelQuotaStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RollingPanelQuotaStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingPanelQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling panel quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedValue() -> Double {
            return ((threshold - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingPanelQuota {
            return RollingPanelQuota(
                code: code,
                title: title,
                threshold: threshold,
                specialty: specialty,
                updatedAt: updatedAt,
                allergy: allergy,
                attempts: attempts,
                clinicianID: clinicianID,
                region: region,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling panel quota in status new.
    static func newRollingPanelQuota(_ code: String, title: String) -> RollingPanelQuota {
        return RollingPanelQuota(
            code: code,
            title: title,
            threshold: 0.0,
            specialty: "",
            updatedAt: 0,
            allergy: "",
            attempts: 0,
            clinicianID: "",
            region: "",
            summary: "",
            status: RollingPanelQuotaStatus.new
        )
    }
}
