import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set score is in its life cycle.
    enum OrderSetScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A order set score. Its code is unique within a tenant.
    final class OrderSetScore {
        var code: String
        var name: String
        var visitMinutes: Int
        var ceiling: Double
        var weight: Double
        var ward: String
        var endsAt: Int
        var acuity: Int
        var threshold: Double
        var status: OrderSetScoreStatus

        init(code: String, name: String, visitMinutes: Int, ceiling: Double, weight: Double, ward: String, endsAt: Int, acuity: Int, threshold: Double, status: OrderSetScoreStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.weight = weight
            self.ward = ward
            self.endsAt = endsAt
            self.acuity = acuity
            self.threshold = threshold
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

        func canMoveTo(_ next: OrderSetScoreStatus) -> Bool {
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
                return next == OrderSetScoreStatus.suspended
            case .active:
                return next == OrderSetScoreStatus.suspended || next == OrderSetScoreStatus.closed
            case .suspended:
                return next == OrderSetScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("order set score") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(endsAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetScore {
            return OrderSetScore(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                weight: weight,
                ward: ward,
                endsAt: endsAt,
                acuity: acuity,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a order set score in status draft.
    static func newOrderSetScore(_ code: String, name: String) -> OrderSetScore {
        return OrderSetScore(
            code: code,
            name: name,
            visitMinutes: 0,
            ceiling: 0.0,
            weight: 0.0,
            ward: "",
            endsAt: 0,
            acuity: 0,
            threshold: 0.0,
            status: OrderSetScoreStatus.draft
        )
    }
}
