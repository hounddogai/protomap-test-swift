import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier rollup is in its life cycle.
    enum CourierRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A courier rollup as the courier team keeps it.
    final class CourierRollup {
        var code: String
        var title: String
        var unit: String
        var patientRef: String
        var country: String
        var version: Int
        var status: CourierRollupStatus

        init(code: String, title: String, unit: String, patientRef: String, country: String, version: Int, status: CourierRollupStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.patientRef = patientRef
            self.country = country
            self.version = version
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

        func canMoveTo(_ next: CourierRollupStatus) -> Bool {
            switch status {
            case .planned:
                return next == CourierRollupStatus.scheduled
            case .scheduled:
                return next == CourierRollupStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CourierRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> CourierRollup {
            return CourierRollup(
                code: code,
                title: title,
                unit: unit,
                patientRef: patientRef,
                country: country,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a courier rollup in status planned.
    static func newCourierRollup(_ code: String, title: String) -> CourierRollup {
        return CourierRollup(
            code: code,
            title: title,
            unit: "",
            patientRef: "",
            country: "",
            version: 0,
            status: CourierRollupStatus.planned
        )
    }
}
