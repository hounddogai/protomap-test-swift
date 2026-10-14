import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional eligibility record is in its life cycle.
    enum RegionalEligibilityRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional eligibility record and its current status.
    final class RegionalEligibilityRecord {
        var code: String
        var label: String
        var rate: Double
        var discount: Double
        var category: String
        var priority: Int
        var title: String
        var graceDays: Int
        var contactEmail: String
        var source: String
        var endsAt: Int
        var status: RegionalEligibilityRecordStatus

        init(code: String, label: String, rate: Double, discount: Double, category: String, priority: Int, title: String, graceDays: Int, contactEmail: String, source: String, endsAt: Int, status: RegionalEligibilityRecordStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.discount = discount
            self.category = category
            self.priority = priority
            self.title = title
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.source = source
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalEligibilityRecordStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RegionalEligibilityRecordStatus.completed
            case .completed:
                return next == RegionalEligibilityRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalEligibilityRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional eligibility record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveVolume() -> Double {
            return ((Double(priority) + discount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalEligibilityRecord {
            return RegionalEligibilityRecord(
                code: code,
                label: label,
                rate: rate,
                discount: discount,
                category: category,
                priority: priority,
                title: title,
                graceDays: graceDays,
                contactEmail: contactEmail,
                source: source,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional eligibility record in status planned.
    static func newRegionalEligibilityRecord(_ code: String, label: String) -> RegionalEligibilityRecord {
        return RegionalEligibilityRecord(
            code: code,
            label: label,
            rate: 0.0,
            discount: 0.0,
            category: "",
            priority: 0,
            title: "",
            graceDays: 0,
            contactEmail: "",
            source: "",
            endsAt: 0,
            status: RegionalEligibilityRecordStatus.planned
        )
    }
}
