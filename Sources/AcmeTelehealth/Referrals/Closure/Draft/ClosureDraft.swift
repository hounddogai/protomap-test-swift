import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure draft is in its life cycle.
    enum ClosureDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a closure draft and its current status.
    final class ClosureDraft {
        var code: String
        var name: String
        var allergy: String
        var region: String
        var quantity: Int
        var archived: Bool
        var currency: String
        var externalRef: String
        var tags: [String]
        var active: Bool
        var status: ClosureDraftStatus

        init(code: String, name: String, allergy: String, region: String, quantity: Int, archived: Bool, currency: String, externalRef: String, tags: [String], active: Bool, status: ClosureDraftStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.region = region
            self.quantity = quantity
            self.archived = archived
            self.currency = currency
            self.externalRef = externalRef
            self.tags = tags
            self.active = active
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

        func canMoveTo(_ next: ClosureDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ClosureDraftStatus.archived
            case .resolved:
                return next == ClosureDraftStatus.reopened || next == ClosureDraftStatus.archived
            case .reopened:
                return next == ClosureDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ClosureDraft {
            return ClosureDraft(
                code: code,
                name: name,
                allergy: allergy,
                region: region,
                quantity: quantity,
                archived: archived,
                currency: currency,
                externalRef: externalRef,
                tags: tags,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a closure draft in status open.
    static func newClosureDraft(_ code: String, name: String) -> ClosureDraft {
        return ClosureDraft(
            code: code,
            name: name,
            allergy: "",
            region: "",
            quantity: 0,
            archived: false,
            currency: "",
            externalRef: "",
            tags: [],
            active: false,
            status: ClosureDraftStatus.`open`
        )
    }
}
