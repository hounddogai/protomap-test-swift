import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen summary is in its life cycle.
    enum SpecimenSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One specimen summary, with what the planners need to act on it.
    final class SpecimenSummary {
        var code: String
        var name: String
        var capacity: Int
        var procedureCode: String
        var archived: Bool
        var status: SpecimenSummaryStatus

        init(code: String, name: String, capacity: Int, procedureCode: String, archived: Bool, status: SpecimenSummaryStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.procedureCode = procedureCode
            self.archived = archived
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

        func canMoveTo(_ next: SpecimenSummaryStatus) -> Bool {
            switch status {
            case .new:
                return next == SpecimenSummaryStatus.failed
            case .queued:
                return next == SpecimenSummaryStatus.running || next == SpecimenSummaryStatus.done
            case .running:
                return next == SpecimenSummaryStatus.failed
            case .done:
                return next == SpecimenSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> SpecimenSummary {
            return SpecimenSummary(
                code: code,
                name: name,
                capacity: capacity,
                procedureCode: procedureCode,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a specimen summary in status new.
    static func newSpecimenSummary(_ code: String, name: String) -> SpecimenSummary {
        return SpecimenSummary(
            code: code,
            name: name,
            capacity: 0,
            procedureCode: "",
            archived: false,
            status: SpecimenSummaryStatus.new
        )
    }
}
