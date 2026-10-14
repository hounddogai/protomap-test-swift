import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap cycle is in its life cycle.
    enum CareGapCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care gap cycle as the care gap team keeps it.
    final class CareGapCycle {
        var code: String
        var title: String
        var diagnosisCode: String
        var tags: [String]
        var floorValue: Double
        var status: CareGapCycleStatus

        init(code: String, title: String, diagnosisCode: String, tags: [String], floorValue: Double, status: CareGapCycleStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.tags = tags
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CareGapCycleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CareGapCycleStatus.draining || next == CareGapCycleStatus.stopped
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

        func moveTo(_ next: CareGapCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> CareGapCycle {
            return CareGapCycle(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                tags: tags,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care gap cycle in status idle.
    static func newCareGapCycle(_ code: String, title: String) -> CareGapCycle {
        return CareGapCycle(
            code: code,
            title: title,
            diagnosisCode: "",
            tags: [],
            floorValue: 0.0,
            status: CareGapCycleStatus.idle
        )
    }
}
