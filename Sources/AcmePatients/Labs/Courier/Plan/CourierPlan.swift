import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier plan is in its life cycle.
    enum CourierPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a courier plan and its current status.
    final class CourierPlan {
        var code: String
        var name: String
        var patientRef: String
        var version: Int
        var tags: [String]
        var cost: Double
        var label: String
        var status: CourierPlanStatus

        init(code: String, name: String, patientRef: String, version: Int, tags: [String], cost: Double, label: String, status: CourierPlanStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.version = version
            self.tags = tags
            self.cost = cost
            self.label = label
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

        func canMoveTo(_ next: CourierPlanStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
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

        func moveTo(_ next: CourierPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("courier plan") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((cost - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> CourierPlan {
            return CourierPlan(
                code: code,
                name: name,
                patientRef: patientRef,
                version: version,
                tags: tags,
                cost: cost,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier plan in status idle.
    static func newCourierPlan(_ code: String, name: String) -> CourierPlan {
        return CourierPlan(
            code: code,
            name: name,
            patientRef: "",
            version: 0,
            tags: [],
            cost: 0.0,
            label: "",
            status: CourierPlanStatus.idle
        )
    }
}
