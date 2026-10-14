import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy overtime manifest is in its life cycle.
    enum LegacyOvertimeManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a legacy overtime manifest and its current status.
    final class LegacyOvertimeManifest {
        var code: String
        var name: String
        var specialty: String
        var title: String
        var quantity: Int
        var durationMinutes: Int
        var diagnosisCode: String
        var timezone: String
        var sequence: Int
        var patientRef: String
        var status: LegacyOvertimeManifestStatus

        init(code: String, name: String, specialty: String, title: String, quantity: Int, durationMinutes: Int, diagnosisCode: String, timezone: String, sequence: Int, patientRef: String, status: LegacyOvertimeManifestStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.title = title
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.sequence = sequence
            self.patientRef = patientRef
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

        func canMoveTo(_ next: LegacyOvertimeManifestStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyOvertimeManifestStatus.queued
            case .queued:
                switch next {
                case .done:
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

        func moveTo(_ next: LegacyOvertimeManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy overtime manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy overtime manifest") \(code)"
        }

        func netValue() -> Double {
            return ((Double(sequence) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyOvertimeManifest {
            return LegacyOvertimeManifest(
                code: code,
                name: name,
                specialty: specialty,
                title: title,
                quantity: quantity,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                sequence: sequence,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy overtime manifest in status new.
    static func newLegacyOvertimeManifest(_ code: String, name: String) -> LegacyOvertimeManifest {
        return LegacyOvertimeManifest(
            code: code,
            name: name,
            specialty: "",
            title: "",
            quantity: 0,
            durationMinutes: 0,
            diagnosisCode: "",
            timezone: "",
            sequence: 0,
            patientRef: "",
            status: LegacyOvertimeManifestStatus.new
        )
    }
}
