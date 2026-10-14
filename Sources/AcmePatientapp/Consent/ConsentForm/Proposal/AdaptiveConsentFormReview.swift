import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive consent form review is in its life cycle.
    enum AdaptiveConsentFormReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive consent form review. Its code is unique within a tenant.
    final class AdaptiveConsentFormReview {
        var code: String
        var name: String
        var quantity: Int
        var tags: [String]
        var description: String
        var phone: String
        var startsAt: Int
        var refills: Int
        var attributes: [String: String]
        var windowDays: Int
        var status: AdaptiveConsentFormReviewStatus

        init(code: String, name: String, quantity: Int, tags: [String], description: String, phone: String, startsAt: Int, refills: Int, attributes: [String: String], windowDays: Int, status: AdaptiveConsentFormReviewStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.tags = tags
            self.description = description
            self.phone = phone
            self.startsAt = startsAt
            self.refills = refills
            self.attributes = attributes
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveConsentFormReviewStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AdaptiveConsentFormReviewStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveConsentFormReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive consent form review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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
            return ((Double(windowDays) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveConsentFormReview {
            return AdaptiveConsentFormReview(
                code: code,
                name: name,
                quantity: quantity,
                tags: tags,
                description: description,
                phone: phone,
                startsAt: startsAt,
                refills: refills,
                attributes: attributes,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive consent form review in status created.
    static func newAdaptiveConsentFormReview(_ code: String, name: String) -> AdaptiveConsentFormReview {
        return AdaptiveConsentFormReview(
            code: code,
            name: name,
            quantity: 0,
            tags: [],
            description: "",
            phone: "",
            startsAt: 0,
            refills: 0,
            attributes: [:],
            windowDays: 0,
            status: AdaptiveConsentFormReviewStatus.created
        )
    }
}
