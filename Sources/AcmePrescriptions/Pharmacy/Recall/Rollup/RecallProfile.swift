import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall profile is in its life cycle.
    enum RecallProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A recall profile. Its code is unique within a tenant.
    final class RecallProfile {
        var code: String
        var name: String
        var quantity: Int
        var startsAt: Int
        var summary: String
        var maximum: Double
        var source: String
        var threshold: Double
        var contactEmail: String
        var tags: [String]
        var batchSize: Int
        var status: RecallProfileStatus

        init(code: String, name: String, quantity: Int, startsAt: Int, summary: String, maximum: Double, source: String, threshold: Double, contactEmail: String, tags: [String], batchSize: Int, status: RecallProfileStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.startsAt = startsAt
            self.summary = summary
            self.maximum = maximum
            self.source = source
            self.threshold = threshold
            self.contactEmail = contactEmail
            self.tags = tags
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RecallProfileStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RecallProfileStatus.failed
            case .done:
                return next == RecallProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((maximum + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RecallProfile {
            return RecallProfile(
                code: code,
                name: name,
                quantity: quantity,
                startsAt: startsAt,
                summary: summary,
                maximum: maximum,
                source: source,
                threshold: threshold,
                contactEmail: contactEmail,
                tags: tags,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a recall profile in status new.
    static func newRecallProfile(_ code: String, name: String) -> RecallProfile {
        return RecallProfile(
            code: code,
            name: name,
            quantity: 0,
            startsAt: 0,
            summary: "",
            maximum: 0.0,
            source: "",
            threshold: 0.0,
            contactEmail: "",
            tags: [],
            batchSize: 0,
            status: RecallProfileStatus.new
        )
    }
}
