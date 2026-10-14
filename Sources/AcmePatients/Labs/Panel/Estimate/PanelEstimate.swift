import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel estimate is in its life cycle.
    enum PanelEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A panel estimate. Its code is unique within a tenant.
    final class PanelEstimate {
        var code: String
        var title: String
        var refills: Int
        var attributes: [String: String]
        var maximum: Double
        var expiresAt: Int
        var score: Double
        var status: PanelEstimateStatus

        init(code: String, title: String, refills: Int, attributes: [String: String], maximum: Double, expiresAt: Int, score: Double, status: PanelEstimateStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.attributes = attributes
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PanelEstimateStatus.approved || next == PanelEstimateStatus.withdrawn
            case .approved:
                return next == PanelEstimateStatus.rejected || next == PanelEstimateStatus.withdrawn
            case .rejected:
                return next == PanelEstimateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("panel estimate") \(code)"
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

        func projectedValue() -> Double {
            return ((Double(expiresAt) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> PanelEstimate {
            return PanelEstimate(
                code: code,
                title: title,
                refills: refills,
                attributes: attributes,
                maximum: maximum,
                expiresAt: expiresAt,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel estimate in status proposed.
    static func newPanelEstimate(_ code: String, title: String) -> PanelEstimate {
        return PanelEstimate(
            code: code,
            title: title,
            refills: 0,
            attributes: [:],
            maximum: 0.0,
            expiresAt: 0,
            score: 0.0,
            status: PanelEstimateStatus.proposed
        )
    }
}
