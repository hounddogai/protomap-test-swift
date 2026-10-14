import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation rollup is in its life cycle.
    enum IsolationRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One isolation rollup, with what the planners need to act on it.
    final class IsolationRollup {
        var code: String
        var title: String
        var weight: Double
        var ward: String
        var label: String
        var specialty: String
        var budget: Double
        var ceiling: Double
        var contactEmail: String
        var approved: Bool
        var status: IsolationRollupStatus

        init(code: String, title: String, weight: Double, ward: String, label: String, specialty: String, budget: Double, ceiling: Double, contactEmail: String, approved: Bool, status: IsolationRollupStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.ward = ward
            self.label = label
            self.specialty = specialty
            self.budget = budget
            self.ceiling = ceiling
            self.contactEmail = contactEmail
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == IsolationRollupStatus.active || next == IsolationRollupStatus.closed
            case .pending:
                return next == IsolationRollupStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: IsolationRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func effectiveExposure() -> Double {
            return (budget * ceiling * 100).rounded() / 100
        }

        func copyValue() -> IsolationRollup {
            return IsolationRollup(
                code: code,
                title: title,
                weight: weight,
                ward: ward,
                label: label,
                specialty: specialty,
                budget: budget,
                ceiling: ceiling,
                contactEmail: contactEmail,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a isolation rollup in status draft.
    static func newIsolationRollup(_ code: String, title: String) -> IsolationRollup {
        return IsolationRollup(
            code: code,
            title: title,
            weight: 0.0,
            ward: "",
            label: "",
            specialty: "",
            budget: 0.0,
            ceiling: 0.0,
            contactEmail: "",
            approved: false,
            status: IsolationRollupStatus.draft
        )
    }
}
