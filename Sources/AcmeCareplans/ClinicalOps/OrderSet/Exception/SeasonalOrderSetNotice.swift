import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal order set notice is in its life cycle.
    enum SeasonalOrderSetNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal order set notice as the order set team keeps it.
    final class SeasonalOrderSetNotice {
        var code: String
        var label: String
        var ratio: Double
        var notes: String
        var retries: Int
        var budget: Double
        var status: SeasonalOrderSetNoticeStatus

        init(code: String, label: String, ratio: Double, notes: String, retries: Int, budget: Double, status: SeasonalOrderSetNoticeStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.notes = notes
            self.retries = retries
            self.budget = budget
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

        func canMoveTo(_ next: SeasonalOrderSetNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SeasonalOrderSetNoticeStatus.done || next == SeasonalOrderSetNoticeStatus.failed
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

        func moveTo(_ next: SeasonalOrderSetNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal order set notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal order set notice") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(retries) + budget) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalOrderSetNotice {
            return SeasonalOrderSetNotice(
                code: code,
                label: label,
                ratio: ratio,
                notes: notes,
                retries: retries,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal order set notice in status new.
    static func newSeasonalOrderSetNotice(_ code: String, label: String) -> SeasonalOrderSetNotice {
        return SeasonalOrderSetNotice(
            code: code,
            label: label,
            ratio: 0.0,
            notes: "",
            retries: 0,
            budget: 0.0,
            status: SeasonalOrderSetNoticeStatus.new
        )
    }
}
