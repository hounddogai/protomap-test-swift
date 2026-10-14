import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched courier tier is in its life cycle.
    enum BatchedCourierTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One batched courier tier, with what the planners need to act on it.
    final class BatchedCourierTier {
        var code: String
        var label: String
        var floorValue: Double
        var encounterID: String
        var createdAt: Int
        var country: String
        var tags: [String]
        var locale: String
        var refills: Int
        var status: BatchedCourierTierStatus

        init(code: String, label: String, floorValue: Double, encounterID: String, createdAt: Int, country: String, tags: [String], locale: String, refills: Int, status: BatchedCourierTierStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.encounterID = encounterID
            self.createdAt = createdAt
            self.country = country
            self.tags = tags
            self.locale = locale
            self.refills = refills
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

        func canMoveTo(_ next: BatchedCourierTierStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
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
                return next == BatchedCourierTierStatus.reopened || next == BatchedCourierTierStatus.archived
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

        func moveTo(_ next: BatchedCourierTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched courier tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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
            return ((Double(refills) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCourierTier {
            return BatchedCourierTier(
                code: code,
                label: label,
                floorValue: floorValue,
                encounterID: encounterID,
                createdAt: createdAt,
                country: country,
                tags: tags,
                locale: locale,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched courier tier in status open.
    static func newBatchedCourierTier(_ code: String, label: String) -> BatchedCourierTier {
        return BatchedCourierTier(
            code: code,
            label: label,
            floorValue: 0.0,
            encounterID: "",
            createdAt: 0,
            country: "",
            tags: [],
            locale: "",
            refills: 0,
            status: BatchedCourierTierStatus.`open`
        )
    }
}
