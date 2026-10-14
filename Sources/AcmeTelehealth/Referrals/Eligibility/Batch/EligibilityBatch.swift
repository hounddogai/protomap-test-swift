import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility batch is in its life cycle.
    enum EligibilityBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A eligibility batch. Its code is unique within a tenant.
    final class EligibilityBatch {
        var code: String
        var title: String
        var minimum: Double
        var refills: Int
        var bed: String
        var country: String
        var source: String
        var timezone: String
        var margin: Double
        var procedureCode: String
        var status: EligibilityBatchStatus

        init(code: String, title: String, minimum: Double, refills: Int, bed: String, country: String, source: String, timezone: String, margin: Double, procedureCode: String, status: EligibilityBatchStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.refills = refills
            self.bed = bed
            self.country = country
            self.source = source
            self.timezone = timezone
            self.margin = margin
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: EligibilityBatchStatus) -> Bool {
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
                return next == EligibilityBatchStatus.running
            case .running:
                return next == EligibilityBatchStatus.done || next == EligibilityBatchStatus.failed
            case .done:
                return next == EligibilityBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedTotal() -> Double {
            return ((minimum - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityBatch {
            return EligibilityBatch(
                code: code,
                title: title,
                minimum: minimum,
                refills: refills,
                bed: bed,
                country: country,
                source: source,
                timezone: timezone,
                margin: margin,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a eligibility batch in status new.
    static func newEligibilityBatch(_ code: String, title: String) -> EligibilityBatch {
        return EligibilityBatch(
            code: code,
            title: title,
            minimum: 0.0,
            refills: 0,
            bed: "",
            country: "",
            source: "",
            timezone: "",
            margin: 0.0,
            procedureCode: "",
            status: EligibilityBatchStatus.new
        )
    }
}
