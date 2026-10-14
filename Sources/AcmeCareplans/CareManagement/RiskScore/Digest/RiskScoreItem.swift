import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score item is in its life cycle.
    enum RiskScoreItemStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A risk score item as the risk score team keeps it.
    final class RiskScoreItem {
        var code: String
        var label: String
        var title: String
        var region: String
        var externalRef: String
        var reviewer: String
        var dosageMg: Double
        var status: RiskScoreItemStatus

        init(code: String, label: String, title: String, region: String, externalRef: String, reviewer: String, dosageMg: Double, status: RiskScoreItemStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.region = region
            self.externalRef = externalRef
            self.reviewer = reviewer
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: RiskScoreItemStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RiskScoreItemStatus.revoked || next == RiskScoreItemStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RiskScoreItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> RiskScoreItem {
            return RiskScoreItem(
                code: code,
                label: label,
                title: title,
                region: region,
                externalRef: externalRef,
                reviewer: reviewer,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a risk score item in status requested.
    static func newRiskScoreItem(_ code: String, label: String) -> RiskScoreItem {
        return RiskScoreItem(
            code: code,
            label: label,
            title: "",
            region: "",
            externalRef: "",
            reviewer: "",
            dosageMg: 0.0,
            status: RiskScoreItemStatus.requested
        )
    }
}
