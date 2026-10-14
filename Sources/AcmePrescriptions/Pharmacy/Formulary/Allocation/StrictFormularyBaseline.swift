import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict formulary baseline is in its life cycle.
    enum StrictFormularyBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict formulary baseline as the formulary team keeps it.
    final class StrictFormularyBaseline {
        var code: String
        var title: String
        var windowDays: Int
        var segment: String
        var ratio: Double
        var ownerID: String
        var updatedAt: Int
        var durationMinutes: Int
        var region: String
        var maximum: Double
        var allergy: String
        var status: StrictFormularyBaselineStatus

        init(code: String, title: String, windowDays: Int, segment: String, ratio: Double, ownerID: String, updatedAt: Int, durationMinutes: Int, region: String, maximum: Double, allergy: String, status: StrictFormularyBaselineStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.segment = segment
            self.ratio = ratio
            self.ownerID = ownerID
            self.updatedAt = updatedAt
            self.durationMinutes = durationMinutes
            self.region = region
            self.maximum = maximum
            self.allergy = allergy
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

        func canMoveTo(_ next: StrictFormularyBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictFormularyBaselineStatus.running
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == StrictFormularyBaselineStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictFormularyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict formulary baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict formulary baseline") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(durationMinutes) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> StrictFormularyBaseline {
            return StrictFormularyBaseline(
                code: code,
                title: title,
                windowDays: windowDays,
                segment: segment,
                ratio: ratio,
                ownerID: ownerID,
                updatedAt: updatedAt,
                durationMinutes: durationMinutes,
                region: region,
                maximum: maximum,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict formulary baseline in status new.
    static func newStrictFormularyBaseline(_ code: String, title: String) -> StrictFormularyBaseline {
        return StrictFormularyBaseline(
            code: code,
            title: title,
            windowDays: 0,
            segment: "",
            ratio: 0.0,
            ownerID: "",
            updatedAt: 0,
            durationMinutes: 0,
            region: "",
            maximum: 0.0,
            allergy: "",
            status: StrictFormularyBaselineStatus.new
        )
    }
}
