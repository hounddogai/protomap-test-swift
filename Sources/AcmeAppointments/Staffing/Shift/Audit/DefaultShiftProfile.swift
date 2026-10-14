import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default shift profile is in its life cycle.
    enum DefaultShiftProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default shift profile. Its code is unique within a tenant.
    final class DefaultShiftProfile {
        var code: String
        var label: String
        var ward: String
        var segment: String
        var attributes: [String: String]
        var diagnosisCode: String
        var description: String
        var score: Double
        var status: DefaultShiftProfileStatus

        init(code: String, label: String, ward: String, segment: String, attributes: [String: String], diagnosisCode: String, description: String, score: Double, status: DefaultShiftProfileStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.segment = segment
            self.attributes = attributes
            self.diagnosisCode = diagnosisCode
            self.description = description
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultShiftProfileStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultShiftProfileStatus.rejected
            case .approved:
                return next == DefaultShiftProfileStatus.withdrawn
            case .rejected:
                return next == DefaultShiftProfileStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultShiftProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default shift profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> DefaultShiftProfile {
            return DefaultShiftProfile(
                code: code,
                label: label,
                ward: ward,
                segment: segment,
                attributes: attributes,
                diagnosisCode: diagnosisCode,
                description: description,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default shift profile in status proposed.
    static func newDefaultShiftProfile(_ code: String, label: String) -> DefaultShiftProfile {
        return DefaultShiftProfile(
            code: code,
            label: label,
            ward: "",
            segment: "",
            attributes: [:],
            diagnosisCode: "",
            description: "",
            score: 0.0,
            status: DefaultShiftProfileStatus.proposed
        )
    }
}
