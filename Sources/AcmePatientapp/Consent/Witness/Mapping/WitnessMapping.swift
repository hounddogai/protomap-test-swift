import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness mapping is in its life cycle.
    enum WitnessMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A witness mapping. Its code is unique within a tenant.
    final class WitnessMapping {
        var code: String
        var name: String
        var discount: Double
        var score: Double
        var label: String
        var status: WitnessMappingStatus

        init(code: String, name: String, discount: Double, score: Double, label: String, status: WitnessMappingStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.score = score
            self.label = label
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

        func canMoveTo(_ next: WitnessMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == WitnessMappingStatus.draining
            case .warming:
                return next == WitnessMappingStatus.stopped
            case .ready:
                return next == WitnessMappingStatus.draining
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

        func moveTo(_ next: WitnessMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("witness mapping") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((discount + score) * 100).rounded() / 100
        }

        func copyValue() -> WitnessMapping {
            return WitnessMapping(
                code: code,
                name: name,
                discount: discount,
                score: score,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a witness mapping in status idle.
    static func newWitnessMapping(_ code: String, name: String) -> WitnessMapping {
        return WitnessMapping(
            code: code,
            name: name,
            discount: 0.0,
            score: 0.0,
            label: "",
            status: WitnessMappingStatus.idle
        )
    }
}
