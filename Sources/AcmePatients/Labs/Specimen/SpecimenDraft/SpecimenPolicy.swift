import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen policy is in its life cycle.
    enum SpecimenPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a specimen policy and its current status.
    final class SpecimenPolicy {
        var code: String
        var title: String
        var visible: Bool
        var rate: Double
        var payer: String
        var attributes: [String: String]
        var approved: Bool
        var description: String
        var clinicianID: String
        var status: SpecimenPolicyStatus

        init(code: String, title: String, visible: Bool, rate: Double, payer: String, attributes: [String: String], approved: Bool, description: String, clinicianID: String, status: SpecimenPolicyStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.rate = rate
            self.payer = payer
            self.attributes = attributes
            self.approved = approved
            self.description = description
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SpecimenPolicyStatus.resolved
            case .inReview:
                return next == SpecimenPolicyStatus.reopened || next == SpecimenPolicyStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SpecimenPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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
            return rate
        }

        func copyValue() -> SpecimenPolicy {
            return SpecimenPolicy(
                code: code,
                title: title,
                visible: visible,
                rate: rate,
                payer: payer,
                attributes: attributes,
                approved: approved,
                description: description,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a specimen policy in status open.
    static func newSpecimenPolicy(_ code: String, title: String) -> SpecimenPolicy {
        return SpecimenPolicy(
            code: code,
            title: title,
            visible: false,
            rate: 0.0,
            payer: "",
            attributes: [:],
            approved: false,
            description: "",
            clinicianID: "",
            status: SpecimenPolicyStatus.`open`
        )
    }
}
