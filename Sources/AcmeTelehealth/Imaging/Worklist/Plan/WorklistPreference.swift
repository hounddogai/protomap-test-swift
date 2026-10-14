import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist preference is in its life cycle.
    enum WorklistPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A worklist preference. Its code is unique within a tenant.
    final class WorklistPreference {
        var code: String
        var title: String
        var ratio: Double
        var ceiling: Double
        var score: Double
        var retries: Int
        var createdAt: Int
        var label: String
        var attributes: [String: String]
        var status: WorklistPreferenceStatus

        init(code: String, title: String, ratio: Double, ceiling: Double, score: Double, retries: Int, createdAt: Int, label: String, attributes: [String: String], status: WorklistPreferenceStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.ceiling = ceiling
            self.score = score
            self.retries = retries
            self.createdAt = createdAt
            self.label = label
            self.attributes = attributes
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

        func canMoveTo(_ next: WorklistPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WorklistPreferenceStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: WorklistPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
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

        func projectedValue() -> Double {
            return ((score - ratio) * 100).rounded() / 100
        }

        func copyValue() -> WorklistPreference {
            return WorklistPreference(
                code: code,
                title: title,
                ratio: ratio,
                ceiling: ceiling,
                score: score,
                retries: retries,
                createdAt: createdAt,
                label: label,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist preference in status proposed.
    static func newWorklistPreference(_ code: String, title: String) -> WorklistPreference {
        return WorklistPreference(
            code: code,
            title: title,
            ratio: 0.0,
            ceiling: 0.0,
            score: 0.0,
            retries: 0,
            createdAt: 0,
            label: "",
            attributes: [:],
            status: WorklistPreferenceStatus.proposed
        )
    }
}
