import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient specimen milestone is in its life cycle.
    enum LenientSpecimenMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient specimen milestone. Its code is unique within a tenant.
    final class LenientSpecimenMilestone {
        var code: String
        var label: String
        var startsAt: Int
        var attributes: [String: String]
        var expiresAt: Int
        var revision: Int
        var status: LenientSpecimenMilestoneStatus

        init(code: String, label: String, startsAt: Int, attributes: [String: String], expiresAt: Int, revision: Int, status: LenientSpecimenMilestoneStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.revision = revision
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

        func canMoveTo(_ next: LenientSpecimenMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientSpecimenMilestoneStatus.rejected
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

        func moveTo(_ next: LenientSpecimenMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient specimen milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
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

        func weightedVolume() -> Double {
            return ((Double(expiresAt) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientSpecimenMilestone {
            return LenientSpecimenMilestone(
                code: code,
                label: label,
                startsAt: startsAt,
                attributes: attributes,
                expiresAt: expiresAt,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient specimen milestone in status proposed.
    static func newLenientSpecimenMilestone(_ code: String, label: String) -> LenientSpecimenMilestone {
        return LenientSpecimenMilestone(
            code: code,
            label: label,
            startsAt: 0,
            attributes: [:],
            expiresAt: 0,
            revision: 0,
            status: LenientSpecimenMilestoneStatus.proposed
        )
    }
}
