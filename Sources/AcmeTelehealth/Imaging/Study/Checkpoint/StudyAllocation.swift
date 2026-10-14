import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study allocation is in its life cycle.
    enum StudyAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One study allocation, with what the planners need to act on it.
    final class StudyAllocation {
        var code: String
        var name: String
        var summary: String
        var locale: String
        var archived: Bool
        var country: String
        var cost: Double
        var status: StudyAllocationStatus

        init(code: String, name: String, summary: String, locale: String, archived: Bool, country: String, cost: Double, status: StudyAllocationStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.locale = locale
            self.archived = archived
            self.country = country
            self.cost = cost
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

        func canMoveTo(_ next: StudyAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == StudyAllocationStatus.running || next == StudyAllocationStatus.done
            case .running:
                return next == StudyAllocationStatus.done || next == StudyAllocationStatus.failed
            case .done:
                return next == StudyAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> StudyAllocation {
            return StudyAllocation(
                code: code,
                name: name,
                summary: summary,
                locale: locale,
                archived: archived,
                country: country,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a study allocation in status new.
    static func newStudyAllocation(_ code: String, name: String) -> StudyAllocation {
        return StudyAllocation(
            code: code,
            name: name,
            summary: "",
            locale: "",
            archived: false,
            country: "",
            cost: 0.0,
            status: StudyAllocationStatus.new
        )
    }
}
