import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive care gap override is in its life cycle.
    enum AdaptiveCareGapOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive care gap override. Its code is unique within a tenant.
    final class AdaptiveCareGapOverride {
        var code: String
        var label: String
        var contactEmail: String
        var currency: String
        var visitMinutes: Int
        var checksum: String
        var updatedAt: Int
        var score: Double
        var patientRef: String
        var status: AdaptiveCareGapOverrideStatus

        init(code: String, label: String, contactEmail: String, currency: String, visitMinutes: Int, checksum: String, updatedAt: Int, score: Double, patientRef: String, status: AdaptiveCareGapOverrideStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.updatedAt = updatedAt
            self.score = score
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AdaptiveCareGapOverrideStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
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
                return next == AdaptiveCareGapOverrideStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCareGapOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care gap override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive care gap override") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(visitMinutes) * score * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCareGapOverride {
            return AdaptiveCareGapOverride(
                code: code,
                label: label,
                contactEmail: contactEmail,
                currency: currency,
                visitMinutes: visitMinutes,
                checksum: checksum,
                updatedAt: updatedAt,
                score: score,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive care gap override in status new.
    static func newAdaptiveCareGapOverride(_ code: String, label: String) -> AdaptiveCareGapOverride {
        return AdaptiveCareGapOverride(
            code: code,
            label: label,
            contactEmail: "",
            currency: "",
            visitMinutes: 0,
            checksum: "",
            updatedAt: 0,
            score: 0.0,
            patientRef: "",
            status: AdaptiveCareGapOverrideStatus.new
        )
    }
}
