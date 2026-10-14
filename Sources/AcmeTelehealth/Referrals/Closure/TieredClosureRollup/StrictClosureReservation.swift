import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict closure reservation is in its life cycle.
    enum StrictClosureReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One strict closure reservation, with what the planners need to act on it.
    final class StrictClosureReservation {
        var code: String
        var label: String
        var timezone: String
        var diagnosisCode: String
        var description: String
        var externalRef: String
        var floorValue: Double
        var threshold: Double
        var status: StrictClosureReservationStatus

        init(code: String, label: String, timezone: String, diagnosisCode: String, description: String, externalRef: String, floorValue: Double, threshold: Double, status: StrictClosureReservationStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.diagnosisCode = diagnosisCode
            self.description = description
            self.externalRef = externalRef
            self.floorValue = floorValue
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictClosureReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == StrictClosureReservationStatus.resolved || next == StrictClosureReservationStatus.archived
            case .resolved:
                return next == StrictClosureReservationStatus.reopened || next == StrictClosureReservationStatus.archived
            case .reopened:
                return next == StrictClosureReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictClosureReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict closure reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return ((threshold + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> StrictClosureReservation {
            return StrictClosureReservation(
                code: code,
                label: label,
                timezone: timezone,
                diagnosisCode: diagnosisCode,
                description: description,
                externalRef: externalRef,
                floorValue: floorValue,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict closure reservation in status open.
    static func newStrictClosureReservation(_ code: String, label: String) -> StrictClosureReservation {
        return StrictClosureReservation(
            code: code,
            label: label,
            timezone: "",
            diagnosisCode: "",
            description: "",
            externalRef: "",
            floorValue: 0.0,
            threshold: 0.0,
            status: StrictClosureReservationStatus.`open`
        )
    }
}
