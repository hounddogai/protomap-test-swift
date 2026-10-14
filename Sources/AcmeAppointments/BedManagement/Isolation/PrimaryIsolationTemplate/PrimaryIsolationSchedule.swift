import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary isolation schedule is in its life cycle.
    enum PrimaryIsolationScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One primary isolation schedule, with what the planners need to act on it.
    final class PrimaryIsolationSchedule {
        var code: String
        var name: String
        var contactEmail: String
        var country: String
        var label: String
        var visitMinutes: Int
        var graceDays: Int
        var weight: Double
        var status: PrimaryIsolationScheduleStatus

        init(code: String, name: String, contactEmail: String, country: String, label: String, visitMinutes: Int, graceDays: Int, weight: Double, status: PrimaryIsolationScheduleStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.country = country
            self.label = label
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
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

        func canMoveTo(_ next: PrimaryIsolationScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryIsolationScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary isolation schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return ((Double(graceDays) + weight) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryIsolationSchedule {
            return PrimaryIsolationSchedule(
                code: code,
                name: name,
                contactEmail: contactEmail,
                country: country,
                label: label,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary isolation schedule in status open.
    static func newPrimaryIsolationSchedule(_ code: String, name: String) -> PrimaryIsolationSchedule {
        return PrimaryIsolationSchedule(
            code: code,
            name: name,
            contactEmail: "",
            country: "",
            label: "",
            visitMinutes: 0,
            graceDays: 0,
            weight: 0.0,
            status: PrimaryIsolationScheduleStatus.`open`
        )
    }
}
