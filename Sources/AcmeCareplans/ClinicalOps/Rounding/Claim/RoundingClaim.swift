import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding claim is in its life cycle.
    enum RoundingClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rounding claim. Its code is unique within a tenant.
    final class RoundingClaim {
        var code: String
        var name: String
        var acuity: Int
        var sequence: Int
        var updatedAt: Int
        var attributes: [String: String]
        var batchSize: Int
        var status: RoundingClaimStatus

        init(code: String, name: String, acuity: Int, sequence: Int, updatedAt: Int, attributes: [String: String], batchSize: Int, status: RoundingClaimStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.sequence = sequence
            self.updatedAt = updatedAt
            self.attributes = attributes
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RoundingClaimStatus) -> Bool {
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
                case .resolved, .archived:
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
                return next == RoundingClaimStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rounding claim") \(code)"
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

        func projectedValue() -> Double {
            return (Double(updatedAt) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> RoundingClaim {
            return RoundingClaim(
                code: code,
                name: name,
                acuity: acuity,
                sequence: sequence,
                updatedAt: updatedAt,
                attributes: attributes,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding claim in status open.
    static func newRoundingClaim(_ code: String, name: String) -> RoundingClaim {
        return RoundingClaim(
            code: code,
            name: name,
            acuity: 0,
            sequence: 0,
            updatedAt: 0,
            attributes: [:],
            batchSize: 0,
            status: RoundingClaimStatus.`open`
        )
    }
}
