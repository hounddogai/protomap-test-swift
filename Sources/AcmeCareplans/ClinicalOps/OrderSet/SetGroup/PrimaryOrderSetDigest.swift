import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary order set digest is in its life cycle.
    enum PrimaryOrderSetDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a primary order set digest and its current status.
    final class PrimaryOrderSetDigest {
        var code: String
        var title: String
        var attributes: [String: String]
        var contactEmail: String
        var budget: Double
        var capacity: Int
        var maximum: Double
        var acuity: Int
        var name: String
        var expiresAt: Int
        var archived: Bool
        var status: PrimaryOrderSetDigestStatus

        init(code: String, title: String, attributes: [String: String], contactEmail: String, budget: Double, capacity: Int, maximum: Double, acuity: Int, name: String, expiresAt: Int, archived: Bool, status: PrimaryOrderSetDigestStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.contactEmail = contactEmail
            self.budget = budget
            self.capacity = capacity
            self.maximum = maximum
            self.acuity = acuity
            self.name = name
            self.expiresAt = expiresAt
            self.archived = archived
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

        func canMoveTo(_ next: PrimaryOrderSetDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryOrderSetDigestStatus.resolved || next == PrimaryOrderSetDigestStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryOrderSetDigestStatus.reopened || next == PrimaryOrderSetDigestStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryOrderSetDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary order set digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary order set digest") \(code)"
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

        func adjustedTotal() -> Double {
            return (maximum * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOrderSetDigest {
            return PrimaryOrderSetDigest(
                code: code,
                title: title,
                attributes: attributes,
                contactEmail: contactEmail,
                budget: budget,
                capacity: capacity,
                maximum: maximum,
                acuity: acuity,
                name: name,
                expiresAt: expiresAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary order set digest in status open.
    static func newPrimaryOrderSetDigest(_ code: String, title: String) -> PrimaryOrderSetDigest {
        return PrimaryOrderSetDigest(
            code: code,
            title: title,
            attributes: [:],
            contactEmail: "",
            budget: 0.0,
            capacity: 0,
            maximum: 0.0,
            acuity: 0,
            name: "",
            expiresAt: 0,
            archived: false,
            status: PrimaryOrderSetDigestStatus.`open`
        )
    }
}
