import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive formulary digest is in its life cycle.
    enum AdaptiveFormularyDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A adaptive formulary digest as the formulary team keeps it.
    final class AdaptiveFormularyDigest {
        var code: String
        var label: String
        var tags: [String]
        var bed: String
        var amount: Double
        var ownerID: String
        var rate: Double
        var status: AdaptiveFormularyDigestStatus

        init(code: String, label: String, tags: [String], bed: String, amount: Double, ownerID: String, rate: Double, status: AdaptiveFormularyDigestStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.bed = bed
            self.amount = amount
            self.ownerID = ownerID
            self.rate = rate
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

        func canMoveTo(_ next: AdaptiveFormularyDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == AdaptiveFormularyDigestStatus.ready
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == AdaptiveFormularyDigestStatus.draining
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

        func moveTo(_ next: AdaptiveFormularyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive formulary digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive formulary digest") \(code)"
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
            return (amount * rate * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFormularyDigest {
            return AdaptiveFormularyDigest(
                code: code,
                label: label,
                tags: tags,
                bed: bed,
                amount: amount,
                ownerID: ownerID,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive formulary digest in status idle.
    static func newAdaptiveFormularyDigest(_ code: String, label: String) -> AdaptiveFormularyDigest {
        return AdaptiveFormularyDigest(
            code: code,
            label: label,
            tags: [],
            bed: "",
            amount: 0.0,
            ownerID: "",
            rate: 0.0,
            status: AdaptiveFormularyDigestStatus.idle
        )
    }
}
