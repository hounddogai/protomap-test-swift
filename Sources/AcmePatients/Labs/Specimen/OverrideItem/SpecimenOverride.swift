import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen override is in its life cycle.
    enum SpecimenOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a specimen override and its current status.
    final class SpecimenOverride {
        var code: String
        var title: String
        var sequence: Int
        var acuity: Int
        var threshold: Double
        var notes: String
        var locale: String
        var capacity: Int
        var contactEmail: String
        var durationMinutes: Int
        var floorValue: Double
        var status: SpecimenOverrideStatus

        init(code: String, title: String, sequence: Int, acuity: Int, threshold: Double, notes: String, locale: String, capacity: Int, contactEmail: String, durationMinutes: Int, floorValue: Double, status: SpecimenOverrideStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.acuity = acuity
            self.threshold = threshold
            self.notes = notes
            self.locale = locale
            self.capacity = capacity
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SpecimenOverrideStatus) -> Bool {
            switch status {
            case .planned:
                return next == SpecimenOverrideStatus.inProgress
            case .scheduled:
                return next == SpecimenOverrideStatus.completed
            case .inProgress:
                return next == SpecimenOverrideStatus.completed || next == SpecimenOverrideStatus.cancelled
            case .completed:
                return next == SpecimenOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return ((floorValue - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenOverride {
            return SpecimenOverride(
                code: code,
                title: title,
                sequence: sequence,
                acuity: acuity,
                threshold: threshold,
                notes: notes,
                locale: locale,
                capacity: capacity,
                contactEmail: contactEmail,
                durationMinutes: durationMinutes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a specimen override in status planned.
    static func newSpecimenOverride(_ code: String, title: String) -> SpecimenOverride {
        return SpecimenOverride(
            code: code,
            title: title,
            sequence: 0,
            acuity: 0,
            threshold: 0.0,
            notes: "",
            locale: "",
            capacity: 0,
            contactEmail: "",
            durationMinutes: 0,
            floorValue: 0.0,
            status: SpecimenOverrideStatus.planned
        )
    }
}
