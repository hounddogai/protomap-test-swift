import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback interaction digest is in its life cycle.
    enum FallbackInteractionDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a fallback interaction digest and its current status.
    final class FallbackInteractionDigest {
        var code: String
        var name: String
        var batchSize: Int
        var summary: String
        var notes: String
        var discount: Double
        var limit: Int
        var unit: String
        var externalRef: String
        var status: FallbackInteractionDigestStatus

        init(code: String, name: String, batchSize: Int, summary: String, notes: String, discount: Double, limit: Int, unit: String, externalRef: String, status: FallbackInteractionDigestStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.summary = summary
            self.notes = notes
            self.discount = discount
            self.limit = limit
            self.unit = unit
            self.externalRef = externalRef
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

        func canMoveTo(_ next: FallbackInteractionDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackInteractionDigestStatus.inReview || next == FallbackInteractionDigestStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackInteractionDigestStatus.reopened || next == FallbackInteractionDigestStatus.archived
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

        func moveTo(_ next: FallbackInteractionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback interaction digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback interaction digest") \(code)"
        }

        func netLoad() -> Double {
            return (Double(limit) * discount * 100).rounded() / 100
        }

        func copyValue() -> FallbackInteractionDigest {
            return FallbackInteractionDigest(
                code: code,
                name: name,
                batchSize: batchSize,
                summary: summary,
                notes: notes,
                discount: discount,
                limit: limit,
                unit: unit,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback interaction digest in status open.
    static func newFallbackInteractionDigest(_ code: String, name: String) -> FallbackInteractionDigest {
        return FallbackInteractionDigest(
            code: code,
            name: name,
            batchSize: 0,
            summary: "",
            notes: "",
            discount: 0.0,
            limit: 0,
            unit: "",
            externalRef: "",
            status: FallbackInteractionDigestStatus.`open`
        )
    }
}
