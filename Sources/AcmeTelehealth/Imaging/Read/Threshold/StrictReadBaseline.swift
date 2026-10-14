import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict read baseline is in its life cycle.
    enum StrictReadBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict read baseline. Its code is unique within a tenant.
    final class StrictReadBaseline {
        var code: String
        var name: String
        var weight: Double
        var region: String
        var ownerID: String
        var copay: Double
        var active: Bool
        var currency: String
        var batchSize: Int
        var status: StrictReadBaselineStatus

        init(code: String, name: String, weight: Double, region: String, ownerID: String, copay: Double, active: Bool, currency: String, batchSize: Int, status: StrictReadBaselineStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.region = region
            self.ownerID = ownerID
            self.copay = copay
            self.active = active
            self.currency = currency
            self.batchSize = batchSize
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

        func canMoveTo(_ next: StrictReadBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictReadBaselineStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == StrictReadBaselineStatus.suspended
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

        func moveTo(_ next: StrictReadBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict read baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict read baseline") \(code)"
        }

        func projectedLoad() -> Double {
            return ((copay - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> StrictReadBaseline {
            return StrictReadBaseline(
                code: code,
                name: name,
                weight: weight,
                region: region,
                ownerID: ownerID,
                copay: copay,
                active: active,
                currency: currency,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a strict read baseline in status draft.
    static func newStrictReadBaseline(_ code: String, name: String) -> StrictReadBaseline {
        return StrictReadBaseline(
            code: code,
            name: name,
            weight: 0.0,
            region: "",
            ownerID: "",
            copay: 0.0,
            active: false,
            currency: "",
            batchSize: 0,
            status: StrictReadBaselineStatus.draft
        )
    }
}
