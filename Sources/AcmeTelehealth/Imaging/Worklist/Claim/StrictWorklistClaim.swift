import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict worklist claim is in its life cycle.
    enum StrictWorklistClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A strict worklist claim. Its code is unique within a tenant.
    final class StrictWorklistClaim {
        var code: String
        var title: String
        var attributes: [String: String]
        var attempts: Int
        var currency: String
        var allergy: String
        var discount: Double
        var version: Int
        var pinned: Bool
        var category: String
        var checksum: String
        var status: StrictWorklistClaimStatus

        init(code: String, title: String, attributes: [String: String], attempts: Int, currency: String, allergy: String, discount: Double, version: Int, pinned: Bool, category: String, checksum: String, status: StrictWorklistClaimStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.attempts = attempts
            self.currency = currency
            self.allergy = allergy
            self.discount = discount
            self.version = version
            self.pinned = pinned
            self.category = category
            self.checksum = checksum
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

        func canMoveTo(_ next: StrictWorklistClaimStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == StrictWorklistClaimStatus.ready || next == StrictWorklistClaimStatus.draining
            case .ready:
                return next == StrictWorklistClaimStatus.draining
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

        func moveTo(_ next: StrictWorklistClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict worklist claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func effectiveValue() -> Double {
            return ((discount - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> StrictWorklistClaim {
            return StrictWorklistClaim(
                code: code,
                title: title,
                attributes: attributes,
                attempts: attempts,
                currency: currency,
                allergy: allergy,
                discount: discount,
                version: version,
                pinned: pinned,
                category: category,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a strict worklist claim in status idle.
    static func newStrictWorklistClaim(_ code: String, title: String) -> StrictWorklistClaim {
        return StrictWorklistClaim(
            code: code,
            title: title,
            attributes: [:],
            attempts: 0,
            currency: "",
            allergy: "",
            discount: 0.0,
            version: 0,
            pinned: false,
            category: "",
            checksum: "",
            status: StrictWorklistClaimStatus.idle
        )
    }
}
