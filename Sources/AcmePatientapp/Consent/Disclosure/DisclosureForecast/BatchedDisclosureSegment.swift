import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched disclosure segment is in its life cycle.
    enum BatchedDisclosureSegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a batched disclosure segment and its current status.
    final class BatchedDisclosureSegment {
        var code: String
        var name: String
        var specialty: String
        var payer: String
        var category: String
        var attributes: [String: String]
        var cost: Double
        var priority: Int
        var ownerID: String
        var status: BatchedDisclosureSegmentStatus

        init(code: String, name: String, specialty: String, payer: String, category: String, attributes: [String: String], cost: Double, priority: Int, ownerID: String, status: BatchedDisclosureSegmentStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.payer = payer
            self.category = category
            self.attributes = attributes
            self.cost = cost
            self.priority = priority
            self.ownerID = ownerID
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

        func canMoveTo(_ next: BatchedDisclosureSegmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
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
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BatchedDisclosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched disclosure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched disclosure segment") \(code)"
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

        func projectedVolume() -> Double {
            return (cost * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDisclosureSegment {
            return BatchedDisclosureSegment(
                code: code,
                name: name,
                specialty: specialty,
                payer: payer,
                category: category,
                attributes: attributes,
                cost: cost,
                priority: priority,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched disclosure segment in status open.
    static func newBatchedDisclosureSegment(_ code: String, name: String) -> BatchedDisclosureSegment {
        return BatchedDisclosureSegment(
            code: code,
            name: name,
            specialty: "",
            payer: "",
            category: "",
            attributes: [:],
            cost: 0.0,
            priority: 0,
            ownerID: "",
            status: BatchedDisclosureSegmentStatus.`open`
        )
    }
}
