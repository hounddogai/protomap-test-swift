import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution agreement is in its life cycle.
    enum SubstitutionAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A substitution agreement. Its code is unique within a tenant.
    final class SubstitutionAgreement {
        var code: String
        var name: String
        var revision: Int
        var segment: String
        var threshold: Double
        var cost: Double
        var attributes: [String: String]
        var summary: String
        var source: String
        var status: SubstitutionAgreementStatus

        init(code: String, name: String, revision: Int, segment: String, threshold: Double, cost: Double, attributes: [String: String], summary: String, source: String, status: SubstitutionAgreementStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.segment = segment
            self.threshold = threshold
            self.cost = cost
            self.attributes = attributes
            self.summary = summary
            self.source = source
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

        func canMoveTo(_ next: SubstitutionAgreementStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SubstitutionAgreementStatus.revoked || next == SubstitutionAgreementStatus.expired
            case .revoked:
                return next == SubstitutionAgreementStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func adjustedLoad() -> Double {
            return ((cost + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionAgreement {
            return SubstitutionAgreement(
                code: code,
                name: name,
                revision: revision,
                segment: segment,
                threshold: threshold,
                cost: cost,
                attributes: attributes,
                summary: summary,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a substitution agreement in status requested.
    static func newSubstitutionAgreement(_ code: String, name: String) -> SubstitutionAgreement {
        return SubstitutionAgreement(
            code: code,
            name: name,
            revision: 0,
            segment: "",
            threshold: 0.0,
            cost: 0.0,
            attributes: [:],
            summary: "",
            source: "",
            status: SubstitutionAgreementStatus.requested
        )
    }
}
