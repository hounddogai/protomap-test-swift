import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol rollup is in its life cycle.
    enum CareProtocolRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A care protocol rollup as the care protocol team keeps it.
    final class CareProtocolRollup {
        var code: String
        var name: String
        var ward: String
        var refills: Int
        var margin: Double
        var threshold: Double
        var status: CareProtocolRollupStatus

        init(code: String, name: String, ward: String, refills: Int, margin: Double, threshold: Double, status: CareProtocolRollupStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.refills = refills
            self.margin = margin
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolRollupStatus) -> Bool {
            switch status {
            case .created:
                return next == CareProtocolRollupStatus.published || next == CareProtocolRollupStatus.retired
            case .validated:
                return next == CareProtocolRollupStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CareProtocolRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return ((Double(refills) + margin) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolRollup {
            return CareProtocolRollup(
                code: code,
                name: name,
                ward: ward,
                refills: refills,
                margin: margin,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care protocol rollup in status created.
    static func newCareProtocolRollup(_ code: String, name: String) -> CareProtocolRollup {
        return CareProtocolRollup(
            code: code,
            name: name,
            ward: "",
            refills: 0,
            margin: 0.0,
            threshold: 0.0,
            status: CareProtocolRollupStatus.created
        )
    }
}
