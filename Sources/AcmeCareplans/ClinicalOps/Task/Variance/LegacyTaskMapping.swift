import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy task mapping is in its life cycle.
    enum LegacyTaskMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One legacy task mapping, with what the planners need to act on it.
    final class LegacyTaskMapping {
        var code: String
        var title: String
        var margin: Double
        var copay: Double
        var budget: Double
        var patientRef: String
        var ward: String
        var checksum: String
        var attributes: [String: String]
        var label: String
        var status: LegacyTaskMappingStatus

        init(code: String, title: String, margin: Double, copay: Double, budget: Double, patientRef: String, ward: String, checksum: String, attributes: [String: String], label: String, status: LegacyTaskMappingStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.copay = copay
            self.budget = budget
            self.patientRef = patientRef
            self.ward = ward
            self.checksum = checksum
            self.attributes = attributes
            self.label = label
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

        func canMoveTo(_ next: LegacyTaskMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LegacyTaskMappingStatus.inProgress
            case .inProgress:
                return next == LegacyTaskMappingStatus.completed || next == LegacyTaskMappingStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LegacyTaskMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy task mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy task mapping") \(code)"
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

        func projectedExposure() -> Double {
            return (copay * margin * 100).rounded() / 100
        }

        func copyValue() -> LegacyTaskMapping {
            return LegacyTaskMapping(
                code: code,
                title: title,
                margin: margin,
                copay: copay,
                budget: budget,
                patientRef: patientRef,
                ward: ward,
                checksum: checksum,
                attributes: attributes,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy task mapping in status planned.
    static func newLegacyTaskMapping(_ code: String, title: String) -> LegacyTaskMapping {
        return LegacyTaskMapping(
            code: code,
            title: title,
            margin: 0.0,
            copay: 0.0,
            budget: 0.0,
            patientRef: "",
            ward: "",
            checksum: "",
            attributes: [:],
            label: "",
            status: LegacyTaskMappingStatus.planned
        )
    }
}
