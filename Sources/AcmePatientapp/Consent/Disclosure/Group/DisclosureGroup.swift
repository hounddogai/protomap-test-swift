import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure group is in its life cycle.
    enum DisclosureGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One disclosure group, with what the planners need to act on it.
    final class DisclosureGroup {
        var code: String
        var label: String
        var procedureCode: String
        var attributes: [String: String]
        var startsAt: Int
        var encounterID: String
        var specialty: String
        var ceiling: Double
        var cost: Double
        var acuity: Int
        var status: DisclosureGroupStatus

        init(code: String, label: String, procedureCode: String, attributes: [String: String], startsAt: Int, encounterID: String, specialty: String, ceiling: Double, cost: Double, acuity: Int, status: DisclosureGroupStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.startsAt = startsAt
            self.encounterID = encounterID
            self.specialty = specialty
            self.ceiling = ceiling
            self.cost = cost
            self.acuity = acuity
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

        func canMoveTo(_ next: DisclosureGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == DisclosureGroupStatus.revoked || next == DisclosureGroupStatus.expired
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

        func moveTo(_ next: DisclosureGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func effectiveLoad() -> Double {
            return ((Double(startsAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureGroup {
            return DisclosureGroup(
                code: code,
                label: label,
                procedureCode: procedureCode,
                attributes: attributes,
                startsAt: startsAt,
                encounterID: encounterID,
                specialty: specialty,
                ceiling: ceiling,
                cost: cost,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure group in status requested.
    static func newDisclosureGroup(_ code: String, label: String) -> DisclosureGroup {
        return DisclosureGroup(
            code: code,
            label: label,
            procedureCode: "",
            attributes: [:],
            startsAt: 0,
            encounterID: "",
            specialty: "",
            ceiling: 0.0,
            cost: 0.0,
            acuity: 0,
            status: DisclosureGroupStatus.requested
        )
    }
}
