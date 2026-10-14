import AcmePlatform
import Foundation

extension Labs {
    /// Where a default courier preference is in its life cycle.
    enum DefaultCourierPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default courier preference. Its code is unique within a tenant.
    final class DefaultCourierPreference {
        var code: String
        var name: String
        var refills: Int
        var contactEmail: String
        var timezone: String
        var score: Double
        var diagnosisCode: String
        var summary: String
        var attributes: [String: String]
        var sequence: Int
        var status: DefaultCourierPreferenceStatus

        init(code: String, name: String, refills: Int, contactEmail: String, timezone: String, score: Double, diagnosisCode: String, summary: String, attributes: [String: String], sequence: Int, status: DefaultCourierPreferenceStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.attributes = attributes
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

        func canMoveTo(_ next: DefaultCourierPreferenceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == DefaultCourierPreferenceStatus.failed
            case .running:
                return next == DefaultCourierPreferenceStatus.done || next == DefaultCourierPreferenceStatus.failed
            case .done:
                return next == DefaultCourierPreferenceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCourierPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default courier preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func projectedLoad() -> Double {
            return ((score + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCourierPreference {
            return DefaultCourierPreference(
                code: code,
                name: name,
                refills: refills,
                contactEmail: contactEmail,
                timezone: timezone,
                score: score,
                diagnosisCode: diagnosisCode,
                summary: summary,
                attributes: attributes,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default courier preference in status new.
    static func newDefaultCourierPreference(_ code: String, name: String) -> DefaultCourierPreference {
        return DefaultCourierPreference(
            code: code,
            name: name,
            refills: 0,
            contactEmail: "",
            timezone: "",
            score: 0.0,
            diagnosisCode: "",
            summary: "",
            attributes: [:],
            sequence: 0,
            status: DefaultCourierPreferenceStatus.new
        )
    }
}
