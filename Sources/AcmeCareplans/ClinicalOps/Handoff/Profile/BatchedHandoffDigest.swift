import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched handoff digest is in its life cycle.
    enum BatchedHandoffDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched handoff digest as the handoff team keeps it.
    final class BatchedHandoffDigest {
        var code: String
        var title: String
        var endsAt: Int
        var procedureCode: String
        var discount: Double
        var currency: String
        var tags: [String]
        var visitMinutes: Int
        var externalRef: String
        var country: String
        var bed: String
        var status: BatchedHandoffDigestStatus

        init(code: String, title: String, endsAt: Int, procedureCode: String, discount: Double, currency: String, tags: [String], visitMinutes: Int, externalRef: String, country: String, bed: String, status: BatchedHandoffDigestStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.discount = discount
            self.currency = currency
            self.tags = tags
            self.visitMinutes = visitMinutes
            self.externalRef = externalRef
            self.country = country
            self.bed = bed
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

        func canMoveTo(_ next: BatchedHandoffDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedHandoffDigestStatus.ready
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == BatchedHandoffDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedHandoffDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched handoff digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return (Double(endsAt) * discount * 100).rounded() / 100
        }

        func copyValue() -> BatchedHandoffDigest {
            return BatchedHandoffDigest(
                code: code,
                title: title,
                endsAt: endsAt,
                procedureCode: procedureCode,
                discount: discount,
                currency: currency,
                tags: tags,
                visitMinutes: visitMinutes,
                externalRef: externalRef,
                country: country,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched handoff digest in status idle.
    static func newBatchedHandoffDigest(_ code: String, title: String) -> BatchedHandoffDigest {
        return BatchedHandoffDigest(
            code: code,
            title: title,
            endsAt: 0,
            procedureCode: "",
            discount: 0.0,
            currency: "",
            tags: [],
            visitMinutes: 0,
            externalRef: "",
            country: "",
            bed: "",
            status: BatchedHandoffDigestStatus.idle
        )
    }
}
