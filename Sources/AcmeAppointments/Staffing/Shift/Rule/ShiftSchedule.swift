import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift schedule is in its life cycle.
    enum ShiftScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One shift schedule, with what the planners need to act on it.
    final class ShiftSchedule {
        var code: String
        var label: String
        var patientRef: String
        var refills: Int
        var attributes: [String: String]
        var reviewer: String
        var threshold: Double
        var version: Int
        var region: String
        var copay: Double
        var status: ShiftScheduleStatus

        init(code: String, label: String, patientRef: String, refills: Int, attributes: [String: String], reviewer: String, threshold: Double, version: Int, region: String, copay: Double, status: ShiftScheduleStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.refills = refills
            self.attributes = attributes
            self.reviewer = reviewer
            self.threshold = threshold
            self.version = version
            self.region = region
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftScheduleStatus) -> Bool {
            switch status {
            case .created:
                return next == ShiftScheduleStatus.published
            case .validated:
                return next == ShiftScheduleStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ShiftScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
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

        func netVolume() -> Double {
            return ((Double(refills) + copay) * 100).rounded() / 100
        }

        func copyValue() -> ShiftSchedule {
            return ShiftSchedule(
                code: code,
                label: label,
                patientRef: patientRef,
                refills: refills,
                attributes: attributes,
                reviewer: reviewer,
                threshold: threshold,
                version: version,
                region: region,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a shift schedule in status created.
    static func newShiftSchedule(_ code: String, label: String) -> ShiftSchedule {
        return ShiftSchedule(
            code: code,
            label: label,
            patientRef: "",
            refills: 0,
            attributes: [:],
            reviewer: "",
            threshold: 0.0,
            version: 0,
            region: "",
            copay: 0.0,
            status: ShiftScheduleStatus.created
        )
    }
}
