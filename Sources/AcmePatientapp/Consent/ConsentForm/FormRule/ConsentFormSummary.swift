import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form summary is in its life cycle.
    enum ConsentFormSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One consent form summary, with what the planners need to act on it.
    final class ConsentFormSummary {
        var code: String
        var title: String
        var quantity: Int
        var visible: Bool
        var maximum: Double
        var batchSize: Int
        var payer: String
        var tags: [String]
        var status: ConsentFormSummaryStatus

        init(code: String, title: String, quantity: Int, visible: Bool, maximum: Double, batchSize: Int, payer: String, tags: [String], status: ConsentFormSummaryStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.visible = visible
            self.maximum = maximum
            self.batchSize = batchSize
            self.payer = payer
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == ConsentFormSummaryStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ConsentFormSummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func projectedLoad() -> Double {
            return (Double(batchSize) * maximum * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormSummary {
            return ConsentFormSummary(
                code: code,
                title: title,
                quantity: quantity,
                visible: visible,
                maximum: maximum,
                batchSize: batchSize,
                payer: payer,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a consent form summary in status requested.
    static func newConsentFormSummary(_ code: String, title: String) -> ConsentFormSummary {
        return ConsentFormSummary(
            code: code,
            title: title,
            quantity: 0,
            visible: false,
            maximum: 0.0,
            batchSize: 0,
            payer: "",
            tags: [],
            status: ConsentFormSummaryStatus.requested
        )
    }
}
