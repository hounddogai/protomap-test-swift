import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered inventory score is in its life cycle.
    enum TieredInventoryScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered inventory score. Its code is unique within a tenant.
    final class TieredInventoryScore {
        var code: String
        var title: String
        var maximum: Double
        var name: String
        var acuity: Int
        var status: TieredInventoryScoreStatus

        init(code: String, title: String, maximum: Double, name: String, acuity: Int, status: TieredInventoryScoreStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.name = name
            self.acuity = acuity
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

        func canMoveTo(_ next: TieredInventoryScoreStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: TieredInventoryScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered inventory score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered inventory score") \(code)"
        }

        func netLoad() -> Double {
            return ((maximum + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> TieredInventoryScore {
            return TieredInventoryScore(
                code: code,
                title: title,
                maximum: maximum,
                name: name,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered inventory score in status new.
    static func newTieredInventoryScore(_ code: String, title: String) -> TieredInventoryScore {
        return TieredInventoryScore(
            code: code,
            title: title,
            maximum: 0.0,
            name: "",
            acuity: 0,
            status: TieredInventoryScoreStatus.new
        )
    }
}
