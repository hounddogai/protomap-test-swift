import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure group is in its life cycle.
    enum ClosureGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A closure group as the closure team keeps it.
    final class ClosureGroup {
        var code: String
        var title: String
        var approved: Bool
        var facility: String
        var label: String
        var maximum: Double
        var tags: [String]
        var region: String
        var cost: Double
        var status: ClosureGroupStatus

        init(code: String, title: String, approved: Bool, facility: String, label: String, maximum: Double, tags: [String], region: String, cost: Double, status: ClosureGroupStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.facility = facility
            self.label = label
            self.maximum = maximum
            self.tags = tags
            self.region = region
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

        func canMoveTo(_ next: ClosureGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ClosureGroupStatus.done
            case .done:
                return next == ClosureGroupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((cost + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ClosureGroup {
            return ClosureGroup(
                code: code,
                title: title,
                approved: approved,
                facility: facility,
                label: label,
                maximum: maximum,
                tags: tags,
                region: region,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a closure group in status new.
    static func newClosureGroup(_ code: String, title: String) -> ClosureGroup {
        return ClosureGroup(
            code: code,
            title: title,
            approved: false,
            facility: "",
            label: "",
            maximum: 0.0,
            tags: [],
            region: "",
            cost: 0.0,
            status: ClosureGroupStatus.new
        )
    }
}
