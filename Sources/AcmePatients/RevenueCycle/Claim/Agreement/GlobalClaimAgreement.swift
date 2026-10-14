import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global claim agreement is in its life cycle.
    enum GlobalClaimAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One global claim agreement, with what the planners need to act on it.
    final class GlobalClaimAgreement {
        var code: String
        var name: String
        var source: String
        var score: Double
        var encounterID: String
        var weight: Double
        var attributes: [String: String]
        var checksum: String
        var timezone: String
        var status: GlobalClaimAgreementStatus

        init(code: String, name: String, source: String, score: Double, encounterID: String, weight: Double, attributes: [String: String], checksum: String, timezone: String, status: GlobalClaimAgreementStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.score = score
            self.encounterID = encounterID
            self.weight = weight
            self.attributes = attributes
            self.checksum = checksum
            self.timezone = timezone
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

        func canMoveTo(_ next: GlobalClaimAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == GlobalClaimAgreementStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalClaimAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global claim agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func effectiveLoad() -> Double {
            return (weight * score * 100).rounded() / 100
        }

        func copyValue() -> GlobalClaimAgreement {
            return GlobalClaimAgreement(
                code: code,
                name: name,
                source: source,
                score: score,
                encounterID: encounterID,
                weight: weight,
                attributes: attributes,
                checksum: checksum,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global claim agreement in status open.
    static func newGlobalClaimAgreement(_ code: String, name: String) -> GlobalClaimAgreement {
        return GlobalClaimAgreement(
            code: code,
            name: name,
            source: "",
            score: 0.0,
            encounterID: "",
            weight: 0.0,
            attributes: [:],
            checksum: "",
            timezone: "",
            status: GlobalClaimAgreementStatus.`open`
        )
    }
}
