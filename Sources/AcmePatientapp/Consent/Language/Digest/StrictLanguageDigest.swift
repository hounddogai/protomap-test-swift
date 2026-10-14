import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict language digest is in its life cycle.
    enum StrictLanguageDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One strict language digest, with what the planners need to act on it.
    final class StrictLanguageDigest {
        var code: String
        var title: String
        var summary: String
        var discount: Double
        var label: String
        var durationMinutes: Int
        var ownerID: String
        var region: String
        var visitMinutes: Int
        var status: StrictLanguageDigestStatus

        init(code: String, title: String, summary: String, discount: Double, label: String, durationMinutes: Int, ownerID: String, region: String, visitMinutes: Int, status: StrictLanguageDigestStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.discount = discount
            self.label = label
            self.durationMinutes = durationMinutes
            self.ownerID = ownerID
            self.region = region
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: StrictLanguageDigestStatus) -> Bool {
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
                return next == StrictLanguageDigestStatus.retired
            case .published:
                return next == StrictLanguageDigestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictLanguageDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict language digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((discount - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictLanguageDigest {
            return StrictLanguageDigest(
                code: code,
                title: title,
                summary: summary,
                discount: discount,
                label: label,
                durationMinutes: durationMinutes,
                ownerID: ownerID,
                region: region,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a strict language digest in status created.
    static func newStrictLanguageDigest(_ code: String, title: String) -> StrictLanguageDigest {
        return StrictLanguageDigest(
            code: code,
            title: title,
            summary: "",
            discount: 0.0,
            label: "",
            durationMinutes: 0,
            ownerID: "",
            region: "",
            visitMinutes: 0,
            status: StrictLanguageDigestStatus.created
        )
    }
}
