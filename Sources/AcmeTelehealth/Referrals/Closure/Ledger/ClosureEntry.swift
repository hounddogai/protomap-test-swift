import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure entry is in its life cycle.
    enum ClosureEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A closure entry. Its code is unique within a tenant.
    final class ClosureEntry {
        var code: String
        var label: String
        var category: String
        var copay: Double
        var durationMinutes: Int
        var facility: String
        var weight: Double
        var status: ClosureEntryStatus

        init(code: String, label: String, category: String, copay: Double, durationMinutes: Int, facility: String, weight: Double, status: ClosureEntryStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClosureEntryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ClosureEntryStatus.inReview || next == ClosureEntryStatus.reopened
            case .inReview:
                return next == ClosureEntryStatus.archived
            case .resolved:
                return next == ClosureEntryStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ClosureEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return (Double(durationMinutes) * copay * 100).rounded() / 100
        }

        func copyValue() -> ClosureEntry {
            return ClosureEntry(
                code: code,
                label: label,
                category: category,
                copay: copay,
                durationMinutes: durationMinutes,
                facility: facility,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a closure entry in status open.
    static func newClosureEntry(_ code: String, label: String) -> ClosureEntry {
        return ClosureEntry(
            code: code,
            label: label,
            category: "",
            copay: 0.0,
            durationMinutes: 0,
            facility: "",
            weight: 0.0,
            status: ClosureEntryStatus.`open`
        )
    }
}
