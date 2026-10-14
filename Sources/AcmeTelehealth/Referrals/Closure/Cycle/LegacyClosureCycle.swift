import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy closure cycle is in its life cycle.
    enum LegacyClosureCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One legacy closure cycle, with what the planners need to act on it.
    final class LegacyClosureCycle {
        var code: String
        var label: String
        var allergy: String
        var floorValue: Double
        var unit: String
        var windowDays: Int
        var tags: [String]
        var segment: String
        var cost: Double
        var approved: Bool
        var status: LegacyClosureCycleStatus

        init(code: String, label: String, allergy: String, floorValue: Double, unit: String, windowDays: Int, tags: [String], segment: String, cost: Double, approved: Bool, status: LegacyClosureCycleStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.floorValue = floorValue
            self.unit = unit
            self.windowDays = windowDays
            self.tags = tags
            self.segment = segment
            self.cost = cost
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyClosureCycleStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyClosureCycleStatus.ready
            case .warming:
                return next == LegacyClosureCycleStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LegacyClosureCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy closure cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy closure cycle") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((floorValue + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyClosureCycle {
            return LegacyClosureCycle(
                code: code,
                label: label,
                allergy: allergy,
                floorValue: floorValue,
                unit: unit,
                windowDays: windowDays,
                tags: tags,
                segment: segment,
                cost: cost,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy closure cycle in status idle.
    static func newLegacyClosureCycle(_ code: String, label: String) -> LegacyClosureCycle {
        return LegacyClosureCycle(
            code: code,
            label: label,
            allergy: "",
            floorValue: 0.0,
            unit: "",
            windowDays: 0,
            tags: [],
            segment: "",
            cost: 0.0,
            approved: false,
            status: LegacyClosureCycleStatus.idle
        )
    }
}
