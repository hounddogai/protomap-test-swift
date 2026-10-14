import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol proposal is in its life cycle.
    enum CareProtocolProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol proposal. Its code is unique within a tenant.
    final class CareProtocolProposal {
        var code: String
        var title: String
        var encounterID: String
        var expiresAt: Int
        var margin: Double
        var limit: Int
        var startsAt: Int
        var attributes: [String: String]
        var endsAt: Int
        var status: CareProtocolProposalStatus

        init(code: String, title: String, encounterID: String, expiresAt: Int, margin: Double, limit: Int, startsAt: Int, attributes: [String: String], endsAt: Int, status: CareProtocolProposalStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.expiresAt = expiresAt
            self.margin = margin
            self.limit = limit
            self.startsAt = startsAt
            self.attributes = attributes
            self.endsAt = endsAt
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

        func canMoveTo(_ next: CareProtocolProposalStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CareProtocolProposalStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CareProtocolProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("care protocol proposal") \(code)"
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
            return ((margin - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolProposal {
            return CareProtocolProposal(
                code: code,
                title: title,
                encounterID: encounterID,
                expiresAt: expiresAt,
                margin: margin,
                limit: limit,
                startsAt: startsAt,
                attributes: attributes,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol proposal in status idle.
    static func newCareProtocolProposal(_ code: String, title: String) -> CareProtocolProposal {
        return CareProtocolProposal(
            code: code,
            title: title,
            encounterID: "",
            expiresAt: 0,
            margin: 0.0,
            limit: 0,
            startsAt: 0,
            attributes: [:],
            endsAt: 0,
            status: CareProtocolProposalStatus.idle
        )
    }
}
