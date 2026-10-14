import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal request is in its life cycle.
    enum GoalRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A goal request. Its code is unique within a tenant.
    final class GoalRequest {
        var code: String
        var label: String
        var region: String
        var attributes: [String: String]
        var batchSize: Int
        var summary: String
        var tags: [String]
        var status: GoalRequestStatus

        init(code: String, label: String, region: String, attributes: [String: String], batchSize: Int, summary: String, tags: [String], status: GoalRequestStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.attributes = attributes
            self.batchSize = batchSize
            self.summary = summary
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalRequestStatus) -> Bool {
            switch status {
            case .requested:
                return next == GoalRequestStatus.granted || next == GoalRequestStatus.revoked
            case .granted:
                return next == GoalRequestStatus.revoked || next == GoalRequestStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: GoalRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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
            return Double(batchSize)
        }

        func copyValue() -> GoalRequest {
            return GoalRequest(
                code: code,
                label: label,
                region: region,
                attributes: attributes,
                batchSize: batchSize,
                summary: summary,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a goal request in status requested.
    static func newGoalRequest(_ code: String, label: String) -> GoalRequest {
        return GoalRequest(
            code: code,
            label: label,
            region: "",
            attributes: [:],
            batchSize: 0,
            summary: "",
            tags: [],
            status: GoalRequestStatus.requested
        )
    }
}
