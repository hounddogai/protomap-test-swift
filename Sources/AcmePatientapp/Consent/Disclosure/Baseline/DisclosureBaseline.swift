import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure baseline is in its life cycle.
    enum DisclosureBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A disclosure baseline. Its code is unique within a tenant.
    final class DisclosureBaseline {
        var code: String
        var label: String
        var endsAt: Int
        var clinicianID: String
        var visitMinutes: Int
        var status: DisclosureBaselineStatus

        init(code: String, label: String, endsAt: Int, clinicianID: String, visitMinutes: Int, status: DisclosureBaselineStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: DisclosureBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DisclosureBaselineStatus.reopened || next == DisclosureBaselineStatus.archived
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

        func moveTo(_ next: DisclosureBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("disclosure baseline") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(visitMinutes) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureBaseline {
            return DisclosureBaseline(
                code: code,
                label: label,
                endsAt: endsAt,
                clinicianID: clinicianID,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure baseline in status open.
    static func newDisclosureBaseline(_ code: String, label: String) -> DisclosureBaseline {
        return DisclosureBaseline(
            code: code,
            label: label,
            endsAt: 0,
            clinicianID: "",
            visitMinutes: 0,
            status: DisclosureBaselineStatus.`open`
        )
    }
}
