import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary accession window is in its life cycle.
    enum PrimaryAccessionWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary accession window as the accession team keeps it.
    final class PrimaryAccessionWindow {
        var code: String
        var label: String
        var country: String
        var priority: Int
        var margin: Double
        var name: String
        var status: PrimaryAccessionWindowStatus

        init(code: String, label: String, country: String, priority: Int, margin: Double, name: String, status: PrimaryAccessionWindowStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.priority = priority
            self.margin = margin
            self.name = name
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

        func canMoveTo(_ next: PrimaryAccessionWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryAccessionWindowStatus.inReview || next == PrimaryAccessionWindowStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryAccessionWindowStatus.reopened || next == PrimaryAccessionWindowStatus.archived
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

        func moveTo(_ next: PrimaryAccessionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary accession window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveTotal() -> Double {
            return (Double(priority) * margin * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAccessionWindow {
            return PrimaryAccessionWindow(
                code: code,
                label: label,
                country: country,
                priority: priority,
                margin: margin,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary accession window in status open.
    static func newPrimaryAccessionWindow(_ code: String, label: String) -> PrimaryAccessionWindow {
        return PrimaryAccessionWindow(
            code: code,
            label: label,
            country: "",
            priority: 0,
            margin: 0.0,
            name: "",
            status: PrimaryAccessionWindowStatus.`open`
        )
    }
}
