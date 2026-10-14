import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge assignment is in its life cycle.
    enum ChargeAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a charge assignment and its current status.
    final class ChargeAssignment {
        var code: String
        var name: String
        var source: String
        var summary: String
        var rate: Double
        var ceiling: Double
        var pinned: Bool
        var status: ChargeAssignmentStatus

        init(code: String, name: String, source: String, summary: String, rate: Double, ceiling: Double, pinned: Bool, status: ChargeAssignmentStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.summary = summary
            self.rate = rate
            self.ceiling = ceiling
            self.pinned = pinned
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

        func canMoveTo(_ next: ChargeAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ChargeAssignmentStatus.completed
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

        func moveTo(_ next: ChargeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("charge assignment") \(code)"
        }

        func adjustedVolume() -> Double {
            return (ceiling * rate * 100).rounded() / 100
        }

        func copyValue() -> ChargeAssignment {
            return ChargeAssignment(
                code: code,
                name: name,
                source: source,
                summary: summary,
                rate: rate,
                ceiling: ceiling,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a charge assignment in status planned.
    static func newChargeAssignment(_ code: String, name: String) -> ChargeAssignment {
        return ChargeAssignment(
            code: code,
            name: name,
            source: "",
            summary: "",
            rate: 0.0,
            ceiling: 0.0,
            pinned: false,
            status: ChargeAssignmentStatus.planned
        )
    }
}
