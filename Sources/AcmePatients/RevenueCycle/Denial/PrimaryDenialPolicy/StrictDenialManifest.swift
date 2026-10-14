import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict denial manifest is in its life cycle.
    enum StrictDenialManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict denial manifest as the denial team keeps it.
    final class StrictDenialManifest {
        var code: String
        var title: String
        var attributes: [String: String]
        var region: String
        var diagnosisCode: String
        var revision: Int
        var status: StrictDenialManifestStatus

        init(code: String, title: String, attributes: [String: String], region: String, diagnosisCode: String, revision: Int, status: StrictDenialManifestStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictDenialManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == StrictDenialManifestStatus.active || next == StrictDenialManifestStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StrictDenialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict denial manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
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
            return Double(revision)
        }

        func copyValue() -> StrictDenialManifest {
            return StrictDenialManifest(
                code: code,
                title: title,
                attributes: attributes,
                region: region,
                diagnosisCode: diagnosisCode,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a strict denial manifest in status draft.
    static func newStrictDenialManifest(_ code: String, title: String) -> StrictDenialManifest {
        return StrictDenialManifest(
            code: code,
            title: title,
            attributes: [:],
            region: "",
            diagnosisCode: "",
            revision: 0,
            status: StrictDenialManifestStatus.draft
        )
    }
}
