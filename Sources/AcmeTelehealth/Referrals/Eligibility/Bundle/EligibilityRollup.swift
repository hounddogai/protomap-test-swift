import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility rollup is in its life cycle.
    enum EligibilityRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a eligibility rollup and its current status.
    final class EligibilityRollup {
        var code: String
        var title: String
        var category: String
        var visible: Bool
        var floorValue: Double
        var name: String
        var approved: Bool
        var tags: [String]
        var attempts: Int
        var capacity: Int
        var facility: String
        var status: EligibilityRollupStatus

        init(code: String, title: String, category: String, visible: Bool, floorValue: Double, name: String, approved: Bool, tags: [String], attempts: Int, capacity: Int, facility: String, status: EligibilityRollupStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.visible = visible
            self.floorValue = floorValue
            self.name = name
            self.approved = approved
            self.tags = tags
            self.attempts = attempts
            self.capacity = capacity
            self.facility = facility
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

        func canMoveTo(_ next: EligibilityRollupStatus) -> Bool {
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
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == EligibilityRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return (floorValue * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityRollup {
            return EligibilityRollup(
                code: code,
                title: title,
                category: category,
                visible: visible,
                floorValue: floorValue,
                name: name,
                approved: approved,
                tags: tags,
                attempts: attempts,
                capacity: capacity,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a eligibility rollup in status new.
    static func newEligibilityRollup(_ code: String, title: String) -> EligibilityRollup {
        return EligibilityRollup(
            code: code,
            title: title,
            category: "",
            visible: false,
            floorValue: 0.0,
            name: "",
            approved: false,
            tags: [],
            attempts: 0,
            capacity: 0,
            facility: "",
            status: EligibilityRollupStatus.new
        )
    }
}
