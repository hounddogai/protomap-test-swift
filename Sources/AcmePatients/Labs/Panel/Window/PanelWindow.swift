import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel window is in its life cycle.
    enum PanelWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a panel window and its current status.
    final class PanelWindow {
        var code: String
        var name: String
        var ceiling: Double
        var contactEmail: String
        var revision: Int
        var currency: String
        var status: PanelWindowStatus

        init(code: String, name: String, ceiling: Double, contactEmail: String, revision: Int, currency: String, status: PanelWindowStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.contactEmail = contactEmail
            self.revision = revision
            self.currency = currency
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

        func canMoveTo(_ next: PanelWindowStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PanelWindowStatus.resolved
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: PanelWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedExposure() -> Double {
            return (Double(revision) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> PanelWindow {
            return PanelWindow(
                code: code,
                name: name,
                ceiling: ceiling,
                contactEmail: contactEmail,
                revision: revision,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a panel window in status open.
    static func newPanelWindow(_ code: String, name: String) -> PanelWindow {
        return PanelWindow(
            code: code,
            name: name,
            ceiling: 0.0,
            contactEmail: "",
            revision: 0,
            currency: "",
            status: PanelWindowStatus.`open`
        )
    }
}
