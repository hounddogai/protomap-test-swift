import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set checkpoint is in its life cycle.
    enum OrderSetCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a order set checkpoint and its current status.
    final class OrderSetCheckpoint {
        var code: String
        var title: String
        var name: String
        var reviewer: String
        var dosageMg: Double
        var summary: String
        var locale: String
        var facility: String
        var ratio: Double
        var active: Bool
        var status: OrderSetCheckpointStatus

        init(code: String, title: String, name: String, reviewer: String, dosageMg: Double, summary: String, locale: String, facility: String, ratio: Double, active: Bool, status: OrderSetCheckpointStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.summary = summary
            self.locale = locale
            self.facility = facility
            self.ratio = ratio
            self.active = active
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

        func canMoveTo(_ next: OrderSetCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
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
                return next == OrderSetCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("order set checkpoint") \(code)"
        }

        func effectiveValue() -> Double {
            return ((dosageMg - ratio) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetCheckpoint {
            return OrderSetCheckpoint(
                code: code,
                title: title,
                name: name,
                reviewer: reviewer,
                dosageMg: dosageMg,
                summary: summary,
                locale: locale,
                facility: facility,
                ratio: ratio,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a order set checkpoint in status idle.
    static func newOrderSetCheckpoint(_ code: String, title: String) -> OrderSetCheckpoint {
        return OrderSetCheckpoint(
            code: code,
            title: title,
            name: "",
            reviewer: "",
            dosageMg: 0.0,
            summary: "",
            locale: "",
            facility: "",
            ratio: 0.0,
            active: false,
            status: OrderSetCheckpointStatus.idle
        )
    }
}
