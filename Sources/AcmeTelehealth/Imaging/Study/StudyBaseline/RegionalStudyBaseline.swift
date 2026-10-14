import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional study baseline is in its life cycle.
    enum RegionalStudyBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional study baseline. Its code is unique within a tenant.
    final class RegionalStudyBaseline {
        var code: String
        var name: String
        var checksum: String
        var tags: [String]
        var ceiling: Double
        var facility: String
        var priority: Int
        var limit: Int
        var encounterID: String
        var status: RegionalStudyBaselineStatus

        init(code: String, name: String, checksum: String, tags: [String], ceiling: Double, facility: String, priority: Int, limit: Int, encounterID: String, status: RegionalStudyBaselineStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.tags = tags
            self.ceiling = ceiling
            self.facility = facility
            self.priority = priority
            self.limit = limit
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RegionalStudyBaselineStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RegionalStudyBaselineStatus.running
            case .running:
                return next == RegionalStudyBaselineStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RegionalStudyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional study baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return (Double(limit) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStudyBaseline {
            return RegionalStudyBaseline(
                code: code,
                name: name,
                checksum: checksum,
                tags: tags,
                ceiling: ceiling,
                facility: facility,
                priority: priority,
                limit: limit,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional study baseline in status new.
    static func newRegionalStudyBaseline(_ code: String, name: String) -> RegionalStudyBaseline {
        return RegionalStudyBaseline(
            code: code,
            name: name,
            checksum: "",
            tags: [],
            ceiling: 0.0,
            facility: "",
            priority: 0,
            limit: 0,
            encounterID: "",
            status: RegionalStudyBaselineStatus.new
        )
    }
}
