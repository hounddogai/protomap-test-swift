import AcmePlatform
import Foundation

extension Consent {
    /// Where a default disclosure segment is in its life cycle.
    enum DefaultDisclosureSegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a default disclosure segment and its current status.
    final class DefaultDisclosureSegment {
        var code: String
        var label: String
        var maximum: Double
        var endsAt: Int
        var specialty: String
        var expiresAt: Int
        var summary: String
        var locale: String
        var diagnosisCode: String
        var notes: String
        var ceiling: Double
        var status: DefaultDisclosureSegmentStatus

        init(code: String, label: String, maximum: Double, endsAt: Int, specialty: String, expiresAt: Int, summary: String, locale: String, diagnosisCode: String, notes: String, ceiling: Double, status: DefaultDisclosureSegmentStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.endsAt = endsAt
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.summary = summary
            self.locale = locale
            self.diagnosisCode = diagnosisCode
            self.notes = notes
            self.ceiling = ceiling
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

        func canMoveTo(_ next: DefaultDisclosureSegmentStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultDisclosureSegmentStatus.queued || next == DefaultDisclosureSegmentStatus.done
            case .queued:
                return next == DefaultDisclosureSegmentStatus.done || next == DefaultDisclosureSegmentStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == DefaultDisclosureSegmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultDisclosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default disclosure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("default disclosure segment") \(code)"
        }

        func projectedExposure() -> Double {
            return ((ceiling + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultDisclosureSegment {
            return DefaultDisclosureSegment(
                code: code,
                label: label,
                maximum: maximum,
                endsAt: endsAt,
                specialty: specialty,
                expiresAt: expiresAt,
                summary: summary,
                locale: locale,
                diagnosisCode: diagnosisCode,
                notes: notes,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default disclosure segment in status new.
    static func newDefaultDisclosureSegment(_ code: String, label: String) -> DefaultDisclosureSegment {
        return DefaultDisclosureSegment(
            code: code,
            label: label,
            maximum: 0.0,
            endsAt: 0,
            specialty: "",
            expiresAt: 0,
            summary: "",
            locale: "",
            diagnosisCode: "",
            notes: "",
            ceiling: 0.0,
            status: DefaultDisclosureSegmentStatus.new
        )
    }
}
