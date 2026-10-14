import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score group is in its life cycle.
    enum RiskScoreGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a risk score group and its current status.
    final class RiskScoreGroup {
        var code: String
        var title: String
        var floorValue: Double
        var approved: Bool
        var unit: String
        var quantity: Int
        var visitMinutes: Int
        var status: RiskScoreGroupStatus

        init(code: String, title: String, floorValue: Double, approved: Bool, unit: String, quantity: Int, visitMinutes: Int, status: RiskScoreGroupStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.approved = approved
            self.unit = unit
            self.quantity = quantity
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RiskScoreGroupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return ((floorValue + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreGroup {
            return RiskScoreGroup(
                code: code,
                title: title,
                floorValue: floorValue,
                approved: approved,
                unit: unit,
                quantity: quantity,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a risk score group in status new.
    static func newRiskScoreGroup(_ code: String, title: String) -> RiskScoreGroup {
        return RiskScoreGroup(
            code: code,
            title: title,
            floorValue: 0.0,
            approved: false,
            unit: "",
            quantity: 0,
            visitMinutes: 0,
            status: RiskScoreGroupStatus.new
        )
    }
}
