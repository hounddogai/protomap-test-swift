import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict care protocol threshold is in its life cycle.
    enum StrictCareProtocolThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict care protocol threshold, with what the planners need to act on it.
    final class StrictCareProtocolThreshold {
        var code: String
        var name: String
        var segment: String
        var label: String
        var threshold: Double
        var patientRef: String
        var facility: String
        var durationMinutes: Int
        var refills: Int
        var specialty: String
        var sequence: Int
        var status: StrictCareProtocolThresholdStatus

        init(code: String, name: String, segment: String, label: String, threshold: Double, patientRef: String, facility: String, durationMinutes: Int, refills: Int, specialty: String, sequence: Int, status: StrictCareProtocolThresholdStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.label = label
            self.threshold = threshold
            self.patientRef = patientRef
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.refills = refills
            self.specialty = specialty
            self.sequence = sequence
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

        func canMoveTo(_ next: StrictCareProtocolThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictCareProtocolThresholdStatus.failed
            case .queued:
                return next == StrictCareProtocolThresholdStatus.running
            case .running:
                return next == StrictCareProtocolThresholdStatus.done || next == StrictCareProtocolThresholdStatus.failed
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

        func moveTo(_ next: StrictCareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func effectiveLoad() -> Double {
            return ((Double(refills) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> StrictCareProtocolThreshold {
            return StrictCareProtocolThreshold(
                code: code,
                name: name,
                segment: segment,
                label: label,
                threshold: threshold,
                patientRef: patientRef,
                facility: facility,
                durationMinutes: durationMinutes,
                refills: refills,
                specialty: specialty,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict care protocol threshold in status new.
    static func newStrictCareProtocolThreshold(_ code: String, name: String) -> StrictCareProtocolThreshold {
        return StrictCareProtocolThreshold(
            code: code,
            name: name,
            segment: "",
            label: "",
            threshold: 0.0,
            patientRef: "",
            facility: "",
            durationMinutes: 0,
            refills: 0,
            specialty: "",
            sequence: 0,
            status: StrictCareProtocolThresholdStatus.new
        )
    }
}
