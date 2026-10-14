import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy score is in its life cycle.
    enum ProxyScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A proxy score as the proxy team keeps it.
    final class ProxyScore {
        var code: String
        var title: String
        var margin: Double
        var facility: String
        var ratio: Double
        var weight: Double
        var budget: Double
        var status: ProxyScoreStatus

        init(code: String, title: String, margin: Double, facility: String, ratio: Double, weight: Double, budget: Double, status: ProxyScoreStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.facility = facility
            self.ratio = ratio
            self.weight = weight
            self.budget = budget
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

        func canMoveTo(_ next: ProxyScoreStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ProxyScoreStatus.reopened || next == ProxyScoreStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ProxyScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return ((weight - budget) * 100).rounded() / 100
        }

        func copyValue() -> ProxyScore {
            return ProxyScore(
                code: code,
                title: title,
                margin: margin,
                facility: facility,
                ratio: ratio,
                weight: weight,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy score in status open.
    static func newProxyScore(_ code: String, title: String) -> ProxyScore {
        return ProxyScore(
            code: code,
            title: title,
            margin: 0.0,
            facility: "",
            ratio: 0.0,
            weight: 0.0,
            budget: 0.0,
            status: ProxyScoreStatus.`open`
        )
    }
}
