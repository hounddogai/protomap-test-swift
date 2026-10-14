import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution summary is in its life cycle.
    enum SubstitutionSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One substitution summary, with what the planners need to act on it.
    final class SubstitutionSummary {
        var code: String
        var name: String
        var version: Int
        var archived: Bool
        var externalRef: String
        var threshold: Double
        var currency: String
        var copay: Double
        var attributes: [String: String]
        var status: SubstitutionSummaryStatus

        init(code: String, name: String, version: Int, archived: Bool, externalRef: String, threshold: Double, currency: String, copay: Double, attributes: [String: String], status: SubstitutionSummaryStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.archived = archived
            self.externalRef = externalRef
            self.threshold = threshold
            self.currency = currency
            self.copay = copay
            self.attributes = attributes
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

        func canMoveTo(_ next: SubstitutionSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SubstitutionSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("substitution summary") \(code)"
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

        func weightedValue() -> Double {
            return ((threshold - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionSummary {
            return SubstitutionSummary(
                code: code,
                name: name,
                version: version,
                archived: archived,
                externalRef: externalRef,
                threshold: threshold,
                currency: currency,
                copay: copay,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a substitution summary in status idle.
    static func newSubstitutionSummary(_ code: String, name: String) -> SubstitutionSummary {
        return SubstitutionSummary(
            code: code,
            name: name,
            version: 0,
            archived: false,
            externalRef: "",
            threshold: 0.0,
            currency: "",
            copay: 0.0,
            attributes: [:],
            status: SubstitutionSummaryStatus.idle
        )
    }
}
