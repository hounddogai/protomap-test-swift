import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive language summary is in its life cycle.
    enum AdaptiveLanguageSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive language summary, with what the planners need to act on it.
    final class AdaptiveLanguageSummary {
        var code: String
        var name: String
        var floorValue: Double
        var description: String
        var startsAt: Int
        var category: String
        var status: AdaptiveLanguageSummaryStatus

        init(code: String, name: String, floorValue: Double, description: String, startsAt: Int, category: String, status: AdaptiveLanguageSummaryStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.description = description
            self.startsAt = startsAt
            self.category = category
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

        func canMoveTo(_ next: AdaptiveLanguageSummaryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AdaptiveLanguageSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive language summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedLoad() -> Double {
            return ((Double(startsAt) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveLanguageSummary {
            return AdaptiveLanguageSummary(
                code: code,
                name: name,
                floorValue: floorValue,
                description: description,
                startsAt: startsAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive language summary in status draft.
    static func newAdaptiveLanguageSummary(_ code: String, name: String) -> AdaptiveLanguageSummary {
        return AdaptiveLanguageSummary(
            code: code,
            name: name,
            floorValue: 0.0,
            description: "",
            startsAt: 0,
            category: "",
            status: AdaptiveLanguageSummaryStatus.draft
        )
    }
}
