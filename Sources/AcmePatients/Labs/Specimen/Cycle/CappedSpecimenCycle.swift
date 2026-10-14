import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped specimen cycle is in its life cycle.
    enum CappedSpecimenCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One capped specimen cycle, with what the planners need to act on it.
    final class CappedSpecimenCycle {
        var code: String
        var title: String
        var windowDays: Int
        var limit: Int
        var segment: String
        var copay: Double
        var createdAt: Int
        var unit: String
        var status: CappedSpecimenCycleStatus

        init(code: String, title: String, windowDays: Int, limit: Int, segment: String, copay: Double, createdAt: Int, unit: String, status: CappedSpecimenCycleStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.limit = limit
            self.segment = segment
            self.copay = copay
            self.createdAt = createdAt
            self.unit = unit
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

        func canMoveTo(_ next: CappedSpecimenCycleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CappedSpecimenCycleStatus.running || next == CappedSpecimenCycleStatus.failed
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

        func moveTo(_ next: CappedSpecimenCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped specimen cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (Double(windowDays) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedSpecimenCycle {
            return CappedSpecimenCycle(
                code: code,
                title: title,
                windowDays: windowDays,
                limit: limit,
                segment: segment,
                copay: copay,
                createdAt: createdAt,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped specimen cycle in status new.
    static func newCappedSpecimenCycle(_ code: String, title: String) -> CappedSpecimenCycle {
        return CappedSpecimenCycle(
            code: code,
            title: title,
            windowDays: 0,
            limit: 0,
            segment: "",
            copay: 0.0,
            createdAt: 0,
            unit: "",
            status: CappedSpecimenCycleStatus.new
        )
    }
}
