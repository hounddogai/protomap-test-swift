import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation score is in its life cycle.
    enum IsolationScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a isolation score and its current status.
    final class IsolationScore {
        var code: String
        var title: String
        var externalRef: String
        var country: String
        var attributes: [String: String]
        var endsAt: Int
        var refills: Int
        var status: IsolationScoreStatus

        init(code: String, title: String, externalRef: String, country: String, attributes: [String: String], endsAt: Int, refills: Int, status: IsolationScoreStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.country = country
            self.attributes = attributes
            self.endsAt = endsAt
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationScoreStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == IsolationScoreStatus.closed
            case .suspended:
                return next == IsolationScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("isolation score") \(code)"
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

        func netVolume() -> Double {
            return ((Double(refills) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationScore {
            return IsolationScore(
                code: code,
                title: title,
                externalRef: externalRef,
                country: country,
                attributes: attributes,
                endsAt: endsAt,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a isolation score in status draft.
    static func newIsolationScore(_ code: String, title: String) -> IsolationScore {
        return IsolationScore(
            code: code,
            title: title,
            externalRef: "",
            country: "",
            attributes: [:],
            endsAt: 0,
            refills: 0,
            status: IsolationScoreStatus.draft
        )
    }
}
