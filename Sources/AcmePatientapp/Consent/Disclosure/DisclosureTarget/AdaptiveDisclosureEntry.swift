import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive disclosure entry is in its life cycle.
    enum AdaptiveDisclosureEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One adaptive disclosure entry, with what the planners need to act on it.
    final class AdaptiveDisclosureEntry {
        var code: String
        var name: String
        var durationMinutes: Int
        var windowDays: Int
        var discount: Double
        var allergy: String
        var batchSize: Int
        var segment: String
        var status: AdaptiveDisclosureEntryStatus

        init(code: String, name: String, durationMinutes: Int, windowDays: Int, discount: Double, allergy: String, batchSize: Int, segment: String, status: AdaptiveDisclosureEntryStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.discount = discount
            self.allergy = allergy
            self.batchSize = batchSize
            self.segment = segment
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

        func canMoveTo(_ next: AdaptiveDisclosureEntryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AdaptiveDisclosureEntryStatus.failed
            case .running:
                return next == AdaptiveDisclosureEntryStatus.done || next == AdaptiveDisclosureEntryStatus.failed
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

        func moveTo(_ next: AdaptiveDisclosureEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive disclosure entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive disclosure entry") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(durationMinutes) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDisclosureEntry {
            return AdaptiveDisclosureEntry(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                discount: discount,
                allergy: allergy,
                batchSize: batchSize,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive disclosure entry in status new.
    static func newAdaptiveDisclosureEntry(_ code: String, name: String) -> AdaptiveDisclosureEntry {
        return AdaptiveDisclosureEntry(
            code: code,
            name: name,
            durationMinutes: 0,
            windowDays: 0,
            discount: 0.0,
            allergy: "",
            batchSize: 0,
            segment: "",
            status: AdaptiveDisclosureEntryStatus.new
        )
    }
}
