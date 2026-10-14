import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled reference range baseline is in its life cycle.
    enum ScheduledReferenceRangeBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One scheduled reference range baseline, with what the planners need to act on it.
    final class ScheduledReferenceRangeBaseline {
        var code: String
        var label: String
        var segment: String
        var unit: String
        var diagnosisCode: String
        var durationMinutes: Int
        var windowDays: Int
        var attributes: [String: String]
        var country: String
        var bed: String
        var limit: Int
        var status: ScheduledReferenceRangeBaselineStatus

        init(code: String, label: String, segment: String, unit: String, diagnosisCode: String, durationMinutes: Int, windowDays: Int, attributes: [String: String], country: String, bed: String, limit: Int, status: ScheduledReferenceRangeBaselineStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.unit = unit
            self.diagnosisCode = diagnosisCode
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.attributes = attributes
            self.country = country
            self.bed = bed
            self.limit = limit
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

        func canMoveTo(_ next: ScheduledReferenceRangeBaselineStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ScheduledReferenceRangeBaselineStatus.draining || next == ScheduledReferenceRangeBaselineStatus.stopped
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

        func moveTo(_ next: ScheduledReferenceRangeBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled reference range baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveExposure() -> Double {
            return ((Double(windowDays) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledReferenceRangeBaseline {
            return ScheduledReferenceRangeBaseline(
                code: code,
                label: label,
                segment: segment,
                unit: unit,
                diagnosisCode: diagnosisCode,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                attributes: attributes,
                country: country,
                bed: bed,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled reference range baseline in status idle.
    static func newScheduledReferenceRangeBaseline(_ code: String, label: String) -> ScheduledReferenceRangeBaseline {
        return ScheduledReferenceRangeBaseline(
            code: code,
            label: label,
            segment: "",
            unit: "",
            diagnosisCode: "",
            durationMinutes: 0,
            windowDays: 0,
            attributes: [:],
            country: "",
            bed: "",
            limit: 0,
            status: ScheduledReferenceRangeBaselineStatus.idle
        )
    }
}
