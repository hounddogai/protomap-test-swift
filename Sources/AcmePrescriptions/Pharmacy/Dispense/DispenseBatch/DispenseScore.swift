import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense score is in its life cycle.
    enum DispenseScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A dispense score. Its code is unique within a tenant.
    final class DispenseScore {
        var code: String
        var title: String
        var country: String
        var active: Bool
        var margin: Double
        var region: String
        var rate: Double
        var visible: Bool
        var expiresAt: Int
        var limit: Int
        var reviewer: String
        var status: DispenseScoreStatus

        init(code: String, title: String, country: String, active: Bool, margin: Double, region: String, rate: Double, visible: Bool, expiresAt: Int, limit: Int, reviewer: String, status: DispenseScoreStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.active = active
            self.margin = margin
            self.region = region
            self.rate = rate
            self.visible = visible
            self.expiresAt = expiresAt
            self.limit = limit
            self.reviewer = reviewer
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

        func canMoveTo(_ next: DispenseScoreStatus) -> Bool {
            switch status {
            case .idle:
                return next == DispenseScoreStatus.ready
            case .warming:
                return next == DispenseScoreStatus.draining || next == DispenseScoreStatus.stopped
            case .ready:
                return next == DispenseScoreStatus.stopped
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

        func moveTo(_ next: DispenseScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((Double(expiresAt) - rate) * 100).rounded() / 100
        }

        func copyValue() -> DispenseScore {
            return DispenseScore(
                code: code,
                title: title,
                country: country,
                active: active,
                margin: margin,
                region: region,
                rate: rate,
                visible: visible,
                expiresAt: expiresAt,
                limit: limit,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a dispense score in status idle.
    static func newDispenseScore(_ code: String, title: String) -> DispenseScore {
        return DispenseScore(
            code: code,
            title: title,
            country: "",
            active: false,
            margin: 0.0,
            region: "",
            rate: 0.0,
            visible: false,
            expiresAt: 0,
            limit: 0,
            reviewer: "",
            status: DispenseScoreStatus.idle
        )
    }
}
