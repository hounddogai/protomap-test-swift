import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched closure score is in its life cycle.
    enum BatchedClosureScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a batched closure score and its current status.
    final class BatchedClosureScore {
        var code: String
        var label: String
        var refills: Int
        var attributes: [String: String]
        var score: Double
        var ward: String
        var encounterID: String
        var quantity: Int
        var contactEmail: String
        var phone: String
        var status: BatchedClosureScoreStatus

        init(code: String, label: String, refills: Int, attributes: [String: String], score: Double, ward: String, encounterID: String, quantity: Int, contactEmail: String, phone: String, status: BatchedClosureScoreStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.attributes = attributes
            self.score = score
            self.ward = ward
            self.encounterID = encounterID
            self.quantity = quantity
            self.contactEmail = contactEmail
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedClosureScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedClosureScoreStatus.inProgress
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BatchedClosureScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched closure score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func netValue() -> Double {
            return ((Double(refills) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedClosureScore {
            return BatchedClosureScore(
                code: code,
                label: label,
                refills: refills,
                attributes: attributes,
                score: score,
                ward: ward,
                encounterID: encounterID,
                quantity: quantity,
                contactEmail: contactEmail,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a batched closure score in status planned.
    static func newBatchedClosureScore(_ code: String, label: String) -> BatchedClosureScore {
        return BatchedClosureScore(
            code: code,
            label: label,
            refills: 0,
            attributes: [:],
            score: 0.0,
            ward: "",
            encounterID: "",
            quantity: 0,
            contactEmail: "",
            phone: "",
            status: BatchedClosureScoreStatus.planned
        )
    }
}
