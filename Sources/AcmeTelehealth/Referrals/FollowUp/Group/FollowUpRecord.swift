import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up record is in its life cycle.
    enum FollowUpRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A follow up record. Its code is unique within a tenant.
    final class FollowUpRecord {
        var code: String
        var name: String
        var timezone: String
        var ceiling: Double
        var discount: Double
        var refills: Int
        var diagnosisCode: String
        var weight: Double
        var windowDays: Int
        var capacity: Int
        var allergy: String
        var status: FollowUpRecordStatus

        init(code: String, name: String, timezone: String, ceiling: Double, discount: Double, refills: Int, diagnosisCode: String, weight: Double, windowDays: Int, capacity: Int, allergy: String, status: FollowUpRecordStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.ceiling = ceiling
            self.discount = discount
            self.refills = refills
            self.diagnosisCode = diagnosisCode
            self.weight = weight
            self.windowDays = windowDays
            self.capacity = capacity
            self.allergy = allergy
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

        func canMoveTo(_ next: FollowUpRecordStatus) -> Bool {
            switch status {
            case .new:
                return next == FollowUpRecordStatus.queued
            case .queued:
                return next == FollowUpRecordStatus.running || next == FollowUpRecordStatus.failed
            case .running:
                return next == FollowUpRecordStatus.done || next == FollowUpRecordStatus.failed
            case .done:
                return next == FollowUpRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("follow up record") \(code)"
        }

        func netLoad() -> Double {
            return (Double(capacity) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpRecord {
            return FollowUpRecord(
                code: code,
                name: name,
                timezone: timezone,
                ceiling: ceiling,
                discount: discount,
                refills: refills,
                diagnosisCode: diagnosisCode,
                weight: weight,
                windowDays: windowDays,
                capacity: capacity,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a follow up record in status new.
    static func newFollowUpRecord(_ code: String, name: String) -> FollowUpRecord {
        return FollowUpRecord(
            code: code,
            name: name,
            timezone: "",
            ceiling: 0.0,
            discount: 0.0,
            refills: 0,
            diagnosisCode: "",
            weight: 0.0,
            windowDays: 0,
            capacity: 0,
            allergy: "",
            status: FollowUpRecordStatus.new
        )
    }
}
