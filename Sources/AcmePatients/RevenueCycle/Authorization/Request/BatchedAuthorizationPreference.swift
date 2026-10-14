import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched authorization preference is in its life cycle.
    enum BatchedAuthorizationPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched authorization preference as the authorization team keeps it.
    final class BatchedAuthorizationPreference {
        var code: String
        var title: String
        var attributes: [String: String]
        var tags: [String]
        var notes: String
        var acuity: Int
        var patientRef: String
        var diagnosisCode: String
        var externalRef: String
        var status: BatchedAuthorizationPreferenceStatus

        init(code: String, title: String, attributes: [String: String], tags: [String], notes: String, acuity: Int, patientRef: String, diagnosisCode: String, externalRef: String, status: BatchedAuthorizationPreferenceStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.tags = tags
            self.notes = notes
            self.acuity = acuity
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.externalRef = externalRef
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

        func canMoveTo(_ next: BatchedAuthorizationPreferenceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedAuthorizationPreferenceStatus.done || next == BatchedAuthorizationPreferenceStatus.failed
            case .running:
                return next == BatchedAuthorizationPreferenceStatus.done || next == BatchedAuthorizationPreferenceStatus.failed
            case .done:
                return next == BatchedAuthorizationPreferenceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAuthorizationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched authorization preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched authorization preference") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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
            return Double(acuity)
        }

        func copyValue() -> BatchedAuthorizationPreference {
            return BatchedAuthorizationPreference(
                code: code,
                title: title,
                attributes: attributes,
                tags: tags,
                notes: notes,
                acuity: acuity,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched authorization preference in status new.
    static func newBatchedAuthorizationPreference(_ code: String, title: String) -> BatchedAuthorizationPreference {
        return BatchedAuthorizationPreference(
            code: code,
            title: title,
            attributes: [:],
            tags: [],
            notes: "",
            acuity: 0,
            patientRef: "",
            diagnosisCode: "",
            externalRef: "",
            status: BatchedAuthorizationPreferenceStatus.new
        )
    }
}
