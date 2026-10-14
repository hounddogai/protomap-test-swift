import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap digest is in its life cycle.
    enum CareGapDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One care gap digest, with what the planners need to act on it.
    final class CareGapDigest {
        var code: String
        var name: String
        var region: String
        var windowDays: Int
        var description: String
        var quantity: Int
        var tags: [String]
        var status: CareGapDigestStatus

        init(code: String, name: String, region: String, windowDays: Int, description: String, quantity: Int, tags: [String], status: CareGapDigestStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.windowDays = windowDays
            self.description = description
            self.quantity = quantity
            self.tags = tags
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

        func canMoveTo(_ next: CareGapDigestStatus) -> Bool {
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
                switch next {
                case .archived:
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
                return next == CareGapDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func weightedExposure() -> Double {
            return (Double(windowDays) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CareGapDigest {
            return CareGapDigest(
                code: code,
                name: name,
                region: region,
                windowDays: windowDays,
                description: description,
                quantity: quantity,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care gap digest in status open.
    static func newCareGapDigest(_ code: String, name: String) -> CareGapDigest {
        return CareGapDigest(
            code: code,
            name: name,
            region: "",
            windowDays: 0,
            description: "",
            quantity: 0,
            tags: [],
            status: CareGapDigestStatus.`open`
        )
    }
}
