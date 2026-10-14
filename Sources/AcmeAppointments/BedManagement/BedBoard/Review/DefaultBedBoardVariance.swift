import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default bed board variance is in its life cycle.
    enum DefaultBedBoardVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default bed board variance. Its code is unique within a tenant.
    final class DefaultBedBoardVariance {
        var code: String
        var label: String
        var acuity: Int
        var capacity: Int
        var durationMinutes: Int
        var status: DefaultBedBoardVarianceStatus

        init(code: String, label: String, acuity: Int, capacity: Int, durationMinutes: Int, status: DefaultBedBoardVarianceStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.capacity = capacity
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: DefaultBedBoardVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultBedBoardVarianceStatus.queued || next == DefaultBedBoardVarianceStatus.running
            case .queued:
                switch next {
                case .running, .failed:
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

        func moveTo(_ next: DefaultBedBoardVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default bed board variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return (Double(capacity) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> DefaultBedBoardVariance {
            return DefaultBedBoardVariance(
                code: code,
                label: label,
                acuity: acuity,
                capacity: capacity,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default bed board variance in status new.
    static func newDefaultBedBoardVariance(_ code: String, label: String) -> DefaultBedBoardVariance {
        return DefaultBedBoardVariance(
            code: code,
            label: label,
            acuity: 0,
            capacity: 0,
            durationMinutes: 0,
            status: DefaultBedBoardVarianceStatus.new
        )
    }
}
