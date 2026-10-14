import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen allocation is in its life cycle.
    enum SpecimenAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One specimen allocation, with what the planners need to act on it.
    final class SpecimenAllocation {
        var code: String
        var title: String
        var region: String
        var visible: Bool
        var name: String
        var score: Double
        var status: SpecimenAllocationStatus

        init(code: String, title: String, region: String, visible: Bool, name: String, score: Double, status: SpecimenAllocationStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.visible = visible
            self.name = name
            self.score = score
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

        func canMoveTo(_ next: SpecimenAllocationStatus) -> Bool {
            switch status {
            case .new:
                return next == SpecimenAllocationStatus.queued || next == SpecimenAllocationStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SpecimenAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> SpecimenAllocation {
            return SpecimenAllocation(
                code: code,
                title: title,
                region: region,
                visible: visible,
                name: name,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a specimen allocation in status new.
    static func newSpecimenAllocation(_ code: String, title: String) -> SpecimenAllocation {
        return SpecimenAllocation(
            code: code,
            title: title,
            region: "",
            visible: false,
            name: "",
            score: 0.0,
            status: SpecimenAllocationStatus.new
        )
    }
}
