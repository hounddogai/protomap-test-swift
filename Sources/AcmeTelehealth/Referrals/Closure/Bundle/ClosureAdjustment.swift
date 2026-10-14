import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure adjustment is in its life cycle.
    enum ClosureAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A closure adjustment as the closure team keeps it.
    final class ClosureAdjustment {
        var code: String
        var title: String
        var margin: Double
        var country: String
        var copay: Double
        var weight: Double
        var ratio: Double
        var tags: [String]
        var status: ClosureAdjustmentStatus

        init(code: String, title: String, margin: Double, country: String, copay: Double, weight: Double, ratio: Double, tags: [String], status: ClosureAdjustmentStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.country = country
            self.copay = copay
            self.weight = weight
            self.ratio = ratio
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClosureAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == ClosureAdjustmentStatus.scheduled || next == ClosureAdjustmentStatus.inProgress
            case .scheduled:
                return next == ClosureAdjustmentStatus.inProgress || next == ClosureAdjustmentStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ClosureAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((weight - copay) * 100).rounded() / 100
        }

        func copyValue() -> ClosureAdjustment {
            return ClosureAdjustment(
                code: code,
                title: title,
                margin: margin,
                country: country,
                copay: copay,
                weight: weight,
                ratio: ratio,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a closure adjustment in status planned.
    static func newClosureAdjustment(_ code: String, title: String) -> ClosureAdjustment {
        return ClosureAdjustment(
            code: code,
            title: title,
            margin: 0.0,
            country: "",
            copay: 0.0,
            weight: 0.0,
            ratio: 0.0,
            tags: [],
            status: ClosureAdjustmentStatus.planned
        )
    }
}
