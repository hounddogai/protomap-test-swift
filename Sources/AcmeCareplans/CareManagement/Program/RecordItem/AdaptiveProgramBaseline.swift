import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive program baseline is in its life cycle.
    enum AdaptiveProgramBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a adaptive program baseline and its current status.
    final class AdaptiveProgramBaseline {
        var code: String
        var title: String
        var visitMinutes: Int
        var rate: Double
        var segment: String
        var name: String
        var expiresAt: Int
        var category: String
        var active: Bool
        var cost: Double
        var status: AdaptiveProgramBaselineStatus

        init(code: String, title: String, visitMinutes: Int, rate: Double, segment: String, name: String, expiresAt: Int, category: String, active: Bool, cost: Double, status: AdaptiveProgramBaselineStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.rate = rate
            self.segment = segment
            self.name = name
            self.expiresAt = expiresAt
            self.category = category
            self.active = active
            self.cost = cost
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

        func canMoveTo(_ next: AdaptiveProgramBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveProgramBaselineStatus.pending
            case .pending:
                return next == AdaptiveProgramBaselineStatus.active
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: AdaptiveProgramBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive program baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return ((Double(visitMinutes) + cost) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveProgramBaseline {
            return AdaptiveProgramBaseline(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                rate: rate,
                segment: segment,
                name: name,
                expiresAt: expiresAt,
                category: category,
                active: active,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive program baseline in status draft.
    static func newAdaptiveProgramBaseline(_ code: String, title: String) -> AdaptiveProgramBaseline {
        return AdaptiveProgramBaseline(
            code: code,
            title: title,
            visitMinutes: 0,
            rate: 0.0,
            segment: "",
            name: "",
            expiresAt: 0,
            category: "",
            active: false,
            cost: 0.0,
            status: AdaptiveProgramBaselineStatus.draft
        )
    }
}
