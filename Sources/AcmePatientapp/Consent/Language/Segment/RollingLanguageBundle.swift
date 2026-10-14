import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling language bundle is in its life cycle.
    enum RollingLanguageBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rolling language bundle, with what the planners need to act on it.
    final class RollingLanguageBundle {
        var code: String
        var label: String
        var revision: Int
        var diagnosisCode: String
        var attributes: [String: String]
        var retries: Int
        var timezone: String
        var approved: Bool
        var amount: Double
        var status: RollingLanguageBundleStatus

        init(code: String, label: String, revision: Int, diagnosisCode: String, attributes: [String: String], retries: Int, timezone: String, approved: Bool, amount: Double, status: RollingLanguageBundleStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
            self.retries = retries
            self.timezone = timezone
            self.approved = approved
            self.amount = amount
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

        func canMoveTo(_ next: RollingLanguageBundleStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingLanguageBundleStatus.validated || next == RollingLanguageBundleStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingLanguageBundleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingLanguageBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling language bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func effectiveTotal() -> Double {
            return ((Double(revision) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RollingLanguageBundle {
            return RollingLanguageBundle(
                code: code,
                label: label,
                revision: revision,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                retries: retries,
                timezone: timezone,
                approved: approved,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling language bundle in status created.
    static func newRollingLanguageBundle(_ code: String, label: String) -> RollingLanguageBundle {
        return RollingLanguageBundle(
            code: code,
            label: label,
            revision: 0,
            diagnosisCode: "",
            attributes: [:],
            retries: 0,
            timezone: "",
            approved: false,
            amount: 0.0,
            status: RollingLanguageBundleStatus.created
        )
    }
}
