import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation window is in its life cycle.
    enum RevocationWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One revocation window, with what the planners need to act on it.
    final class RevocationWindow {
        var code: String
        var title: String
        var payer: String
        var maximum: Double
        var ceiling: Double
        var attributes: [String: String]
        var archived: Bool
        var refills: Int
        var segment: String
        var country: String
        var status: RevocationWindowStatus

        init(code: String, title: String, payer: String, maximum: Double, ceiling: Double, attributes: [String: String], archived: Bool, refills: Int, segment: String, country: String, status: RevocationWindowStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.maximum = maximum
            self.ceiling = ceiling
            self.attributes = attributes
            self.archived = archived
            self.refills = refills
            self.segment = segment
            self.country = country
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

        func canMoveTo(_ next: RevocationWindowStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RevocationWindowStatus.archived
            case .resolved:
                return next == RevocationWindowStatus.reopened || next == RevocationWindowStatus.archived
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

        func moveTo(_ next: RevocationWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("revocation window") \(code)"
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

        func adjustedLoad() -> Double {
            return ((Double(refills) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> RevocationWindow {
            return RevocationWindow(
                code: code,
                title: title,
                payer: payer,
                maximum: maximum,
                ceiling: ceiling,
                attributes: attributes,
                archived: archived,
                refills: refills,
                segment: segment,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a revocation window in status open.
    static func newRevocationWindow(_ code: String, title: String) -> RevocationWindow {
        return RevocationWindow(
            code: code,
            title: title,
            payer: "",
            maximum: 0.0,
            ceiling: 0.0,
            attributes: [:],
            archived: false,
            refills: 0,
            segment: "",
            country: "",
            status: RevocationWindowStatus.`open`
        )
    }
}
