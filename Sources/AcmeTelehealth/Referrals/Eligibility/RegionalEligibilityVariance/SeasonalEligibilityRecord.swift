import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal eligibility record is in its life cycle.
    enum SeasonalEligibilityRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal eligibility record. Its code is unique within a tenant.
    final class SeasonalEligibilityRecord {
        var code: String
        var title: String
        var phone: String
        var cost: Double
        var patientRef: String
        var expiresAt: Int
        var batchSize: Int
        var payer: String
        var graceDays: Int
        var currency: String
        var status: SeasonalEligibilityRecordStatus

        init(code: String, title: String, phone: String, cost: Double, patientRef: String, expiresAt: Int, batchSize: Int, payer: String, graceDays: Int, currency: String, status: SeasonalEligibilityRecordStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.cost = cost
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.payer = payer
            self.graceDays = graceDays
            self.currency = currency
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

        func canMoveTo(_ next: SeasonalEligibilityRecordStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalEligibilityRecordStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SeasonalEligibilityRecordStatus.failed
            case .done:
                return next == SeasonalEligibilityRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalEligibilityRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal eligibility record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal eligibility record") \(code)"
        }

        func projectedValue() -> Double {
            return ((cost - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalEligibilityRecord {
            return SeasonalEligibilityRecord(
                code: code,
                title: title,
                phone: phone,
                cost: cost,
                patientRef: patientRef,
                expiresAt: expiresAt,
                batchSize: batchSize,
                payer: payer,
                graceDays: graceDays,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal eligibility record in status new.
    static func newSeasonalEligibilityRecord(_ code: String, title: String) -> SeasonalEligibilityRecord {
        return SeasonalEligibilityRecord(
            code: code,
            title: title,
            phone: "",
            cost: 0.0,
            patientRef: "",
            expiresAt: 0,
            batchSize: 0,
            payer: "",
            graceDays: 0,
            currency: "",
            status: SeasonalEligibilityRecordStatus.new
        )
    }
}
