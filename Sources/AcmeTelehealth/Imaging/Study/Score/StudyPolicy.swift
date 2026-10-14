import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study policy is in its life cycle.
    enum StudyPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A study policy as the study team keeps it.
    final class StudyPolicy {
        var code: String
        var title: String
        var attributes: [String: String]
        var notes: String
        var active: Bool
        var timezone: String
        var createdAt: Int
        var region: String
        var dosageMg: Double
        var status: StudyPolicyStatus

        init(code: String, title: String, attributes: [String: String], notes: String, active: Bool, timezone: String, createdAt: Int, region: String, dosageMg: Double, status: StudyPolicyStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.notes = notes
            self.active = active
            self.timezone = timezone
            self.createdAt = createdAt
            self.region = region
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: StudyPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StudyPolicyStatus.withdrawn
            case .approved:
                return next == StudyPolicyStatus.rejected
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

        func moveTo(_ next: StudyPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
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

        func effectiveVolume() -> Double {
            return (dosageMg * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> StudyPolicy {
            return StudyPolicy(
                code: code,
                title: title,
                attributes: attributes,
                notes: notes,
                active: active,
                timezone: timezone,
                createdAt: createdAt,
                region: region,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a study policy in status proposed.
    static func newStudyPolicy(_ code: String, title: String) -> StudyPolicy {
        return StudyPolicy(
            code: code,
            title: title,
            attributes: [:],
            notes: "",
            active: false,
            timezone: "",
            createdAt: 0,
            region: "",
            dosageMg: 0.0,
            status: StudyPolicyStatus.proposed
        )
    }
}
