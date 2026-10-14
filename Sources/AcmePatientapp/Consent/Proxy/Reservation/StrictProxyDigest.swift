import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict proxy digest is in its life cycle.
    enum StrictProxyDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a strict proxy digest and its current status.
    final class StrictProxyDigest {
        var code: String
        var name: String
        var payer: String
        var weight: Double
        var tags: [String]
        var endsAt: Int
        var description: String
        var currency: String
        var acuity: Int
        var status: StrictProxyDigestStatus

        init(code: String, name: String, payer: String, weight: Double, tags: [String], endsAt: Int, description: String, currency: String, acuity: Int, status: StrictProxyDigestStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.weight = weight
            self.tags = tags
            self.endsAt = endsAt
            self.description = description
            self.currency = currency
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictProxyDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictProxyDigestStatus.inProgress
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == StrictProxyDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictProxyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict proxy digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
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

        func projectedExposure() -> Double {
            return ((weight + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictProxyDigest {
            return StrictProxyDigest(
                code: code,
                name: name,
                payer: payer,
                weight: weight,
                tags: tags,
                endsAt: endsAt,
                description: description,
                currency: currency,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict proxy digest in status planned.
    static func newStrictProxyDigest(_ code: String, name: String) -> StrictProxyDigest {
        return StrictProxyDigest(
            code: code,
            name: name,
            payer: "",
            weight: 0.0,
            tags: [],
            endsAt: 0,
            description: "",
            currency: "",
            acuity: 0,
            status: StrictProxyDigestStatus.planned
        )
    }
}
