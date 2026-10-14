import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census proposal is in its life cycle.
    enum CensusProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A census proposal. Its code is unique within a tenant.
    final class CensusProposal {
        var code: String
        var title: String
        var expiresAt: Int
        var country: String
        var attributes: [String: String]
        var ward: String
        var maximum: Double
        var durationMinutes: Int
        var priority: Int
        var quantity: Int
        var status: CensusProposalStatus

        init(code: String, title: String, expiresAt: Int, country: String, attributes: [String: String], ward: String, maximum: Double, durationMinutes: Int, priority: Int, quantity: Int, status: CensusProposalStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.country = country
            self.attributes = attributes
            self.ward = ward
            self.maximum = maximum
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.quantity = quantity
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

        func canMoveTo(_ next: CensusProposalStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CensusProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func weightedLoad() -> Double {
            return ((Double(quantity) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CensusProposal {
            return CensusProposal(
                code: code,
                title: title,
                expiresAt: expiresAt,
                country: country,
                attributes: attributes,
                ward: ward,
                maximum: maximum,
                durationMinutes: durationMinutes,
                priority: priority,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a census proposal in status idle.
    static func newCensusProposal(_ code: String, title: String) -> CensusProposal {
        return CensusProposal(
            code: code,
            title: title,
            expiresAt: 0,
            country: "",
            attributes: [:],
            ward: "",
            maximum: 0.0,
            durationMinutes: 0,
            priority: 0,
            quantity: 0,
            status: CensusProposalStatus.idle
        )
    }
}
