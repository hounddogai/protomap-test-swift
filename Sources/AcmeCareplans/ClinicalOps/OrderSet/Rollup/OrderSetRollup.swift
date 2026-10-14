import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set rollup is in its life cycle.
    enum OrderSetRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A order set rollup. Its code is unique within a tenant.
    final class OrderSetRollup {
        var code: String
        var title: String
        var source: String
        var ratio: Double
        var rate: Double
        var patientRef: String
        var discount: Double
        var visible: Bool
        var durationMinutes: Int
        var dosageMg: Double
        var status: OrderSetRollupStatus

        init(code: String, title: String, source: String, ratio: Double, rate: Double, patientRef: String, discount: Double, visible: Bool, durationMinutes: Int, dosageMg: Double, status: OrderSetRollupStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.ratio = ratio
            self.rate = rate
            self.patientRef = patientRef
            self.discount = discount
            self.visible = visible
            self.durationMinutes = durationMinutes
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: OrderSetRollupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
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

        func moveTo(_ next: OrderSetRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("order set rollup") \(code)"
        }

        func netVolume() -> Double {
            return ((rate + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetRollup {
            return OrderSetRollup(
                code: code,
                title: title,
                source: source,
                ratio: ratio,
                rate: rate,
                patientRef: patientRef,
                discount: discount,
                visible: visible,
                durationMinutes: durationMinutes,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a order set rollup in status new.
    static func newOrderSetRollup(_ code: String, title: String) -> OrderSetRollup {
        return OrderSetRollup(
            code: code,
            title: title,
            source: "",
            ratio: 0.0,
            rate: 0.0,
            patientRef: "",
            discount: 0.0,
            visible: false,
            durationMinutes: 0,
            dosageMg: 0.0,
            status: OrderSetRollupStatus.new
        )
    }
}
