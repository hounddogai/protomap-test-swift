import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global isolation summary is in its life cycle.
    enum GlobalIsolationSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global isolation summary. Its code is unique within a tenant.
    final class GlobalIsolationSummary {
        var code: String
        var title: String
        var specialty: String
        var facility: String
        var segment: String
        var payer: String
        var cost: Double
        var reviewer: String
        var ownerID: String
        var status: GlobalIsolationSummaryStatus

        init(code: String, title: String, specialty: String, facility: String, segment: String, payer: String, cost: Double, reviewer: String, ownerID: String, status: GlobalIsolationSummaryStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.facility = facility
            self.segment = segment
            self.payer = payer
            self.cost = cost
            self.reviewer = reviewer
            self.ownerID = ownerID
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

        func canMoveTo(_ next: GlobalIsolationSummaryStatus) -> Bool {
            switch status {
            case .draft:
                return next == GlobalIsolationSummaryStatus.pending || next == GlobalIsolationSummaryStatus.active
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalIsolationSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global isolation summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> GlobalIsolationSummary {
            return GlobalIsolationSummary(
                code: code,
                title: title,
                specialty: specialty,
                facility: facility,
                segment: segment,
                payer: payer,
                cost: cost,
                reviewer: reviewer,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a global isolation summary in status draft.
    static func newGlobalIsolationSummary(_ code: String, title: String) -> GlobalIsolationSummary {
        return GlobalIsolationSummary(
            code: code,
            title: title,
            specialty: "",
            facility: "",
            segment: "",
            payer: "",
            cost: 0.0,
            reviewer: "",
            ownerID: "",
            status: GlobalIsolationSummaryStatus.draft
        )
    }
}
