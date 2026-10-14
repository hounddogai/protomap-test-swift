import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score bundle is in its life cycle.
    enum RiskScoreBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A risk score bundle. Its code is unique within a tenant.
    final class RiskScoreBundle {
        var code: String
        var name: String
        var dosageMg: Double
        var visitMinutes: Int
        var category: String
        var floorValue: Double
        var title: String
        var status: RiskScoreBundleStatus

        init(code: String, name: String, dosageMg: Double, visitMinutes: Int, category: String, floorValue: Double, title: String, status: RiskScoreBundleStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.category = category
            self.floorValue = floorValue
            self.title = title
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

        func canMoveTo(_ next: RiskScoreBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == RiskScoreBundleStatus.warming
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
                case .stopped:
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

        func moveTo(_ next: RiskScoreBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("risk score bundle") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(visitMinutes) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreBundle {
            return RiskScoreBundle(
                code: code,
                name: name,
                dosageMg: dosageMg,
                visitMinutes: visitMinutes,
                category: category,
                floorValue: floorValue,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a risk score bundle in status idle.
    static func newRiskScoreBundle(_ code: String, name: String) -> RiskScoreBundle {
        return RiskScoreBundle(
            code: code,
            name: name,
            dosageMg: 0.0,
            visitMinutes: 0,
            category: "",
            floorValue: 0.0,
            title: "",
            status: RiskScoreBundleStatus.idle
        )
    }
}
