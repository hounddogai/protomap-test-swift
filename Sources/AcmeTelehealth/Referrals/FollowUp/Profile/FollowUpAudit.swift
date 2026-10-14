import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up audit is in its life cycle.
    enum FollowUpAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a follow up audit and its current status.
    final class FollowUpAudit {
        var code: String
        var label: String
        var specialty: String
        var category: String
        var name: String
        var attributes: [String: String]
        var cost: Double
        var status: FollowUpAuditStatus

        init(code: String, label: String, specialty: String, category: String, name: String, attributes: [String: String], cost: Double, status: FollowUpAuditStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.category = category
            self.name = name
            self.attributes = attributes
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpAuditStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FollowUpAuditStatus.draining
            case .draining:
                return next == FollowUpAuditStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> FollowUpAudit {
            return FollowUpAudit(
                code: code,
                label: label,
                specialty: specialty,
                category: category,
                name: name,
                attributes: attributes,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a follow up audit in status idle.
    static func newFollowUpAudit(_ code: String, label: String) -> FollowUpAudit {
        return FollowUpAudit(
            code: code,
            label: label,
            specialty: "",
            category: "",
            name: "",
            attributes: [:],
            cost: 0.0,
            status: FollowUpAuditStatus.idle
        )
    }
}
