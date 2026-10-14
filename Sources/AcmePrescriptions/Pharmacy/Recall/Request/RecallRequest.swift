import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall request is in its life cycle.
    enum RecallRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A recall request. Its code is unique within a tenant.
    final class RecallRequest {
        var code: String
        var label: String
        var currency: String
        var maximum: Double
        var allergy: String
        var rate: Double
        var revision: Int
        var endsAt: Int
        var capacity: Int
        var tags: [String]
        var description: String
        var status: RecallRequestStatus

        init(code: String, label: String, currency: String, maximum: Double, allergy: String, rate: Double, revision: Int, endsAt: Int, capacity: Int, tags: [String], description: String, status: RecallRequestStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.maximum = maximum
            self.allergy = allergy
            self.rate = rate
            self.revision = revision
            self.endsAt = endsAt
            self.capacity = capacity
            self.tags = tags
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RecallRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == RecallRequestStatus.suspended || next == RecallRequestStatus.closed
            case .pending:
                return next == RecallRequestStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RecallRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((Double(capacity) + rate) * 100).rounded() / 100
        }

        func copyValue() -> RecallRequest {
            return RecallRequest(
                code: code,
                label: label,
                currency: currency,
                maximum: maximum,
                allergy: allergy,
                rate: rate,
                revision: revision,
                endsAt: endsAt,
                capacity: capacity,
                tags: tags,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a recall request in status draft.
    static func newRecallRequest(_ code: String, label: String) -> RecallRequest {
        return RecallRequest(
            code: code,
            label: label,
            currency: "",
            maximum: 0.0,
            allergy: "",
            rate: 0.0,
            revision: 0,
            endsAt: 0,
            capacity: 0,
            tags: [],
            description: "",
            status: RecallRequestStatus.draft
        )
    }
}
