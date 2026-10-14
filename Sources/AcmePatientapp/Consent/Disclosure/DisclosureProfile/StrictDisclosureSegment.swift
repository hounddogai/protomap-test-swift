import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict disclosure segment is in its life cycle.
    enum StrictDisclosureSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One strict disclosure segment, with what the planners need to act on it.
    final class StrictDisclosureSegment {
        var code: String
        var name: String
        var graceDays: Int
        var attributes: [String: String]
        var clinicianID: String
        var ratio: Double
        var visible: Bool
        var budget: Double
        var ceiling: Double
        var status: StrictDisclosureSegmentStatus

        init(code: String, name: String, graceDays: Int, attributes: [String: String], clinicianID: String, ratio: Double, visible: Bool, budget: Double, ceiling: Double, status: StrictDisclosureSegmentStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.attributes = attributes
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.visible = visible
            self.budget = budget
            self.ceiling = ceiling
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

        func canMoveTo(_ next: StrictDisclosureSegmentStatus) -> Bool {
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
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StrictDisclosureSegmentStatus.completed || next == StrictDisclosureSegmentStatus.cancelled
            case .completed:
                return next == StrictDisclosureSegmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictDisclosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict disclosure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveLoad() -> Double {
            return (budget * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> StrictDisclosureSegment {
            return StrictDisclosureSegment(
                code: code,
                name: name,
                graceDays: graceDays,
                attributes: attributes,
                clinicianID: clinicianID,
                ratio: ratio,
                visible: visible,
                budget: budget,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict disclosure segment in status planned.
    static func newStrictDisclosureSegment(_ code: String, name: String) -> StrictDisclosureSegment {
        return StrictDisclosureSegment(
            code: code,
            name: name,
            graceDays: 0,
            attributes: [:],
            clinicianID: "",
            ratio: 0.0,
            visible: false,
            budget: 0.0,
            ceiling: 0.0,
            status: StrictDisclosureSegmentStatus.planned
        )
    }
}
