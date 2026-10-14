import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted transfer slot is in its life cycle.
    enum WeightedTransferSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a weighted transfer slot and its current status.
    final class WeightedTransferSlot {
        var code: String
        var name: String
        var payer: String
        var startsAt: Int
        var patientRef: String
        var status: WeightedTransferSlotStatus

        init(code: String, name: String, payer: String, startsAt: Int, patientRef: String, status: WeightedTransferSlotStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.startsAt = startsAt
            self.patientRef = patientRef
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

        func canMoveTo(_ next: WeightedTransferSlotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == WeightedTransferSlotStatus.running || next == WeightedTransferSlotStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WeightedTransferSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTransferSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted transfer slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted transfer slot") \(code)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> WeightedTransferSlot {
            return WeightedTransferSlot(
                code: code,
                name: name,
                payer: payer,
                startsAt: startsAt,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted transfer slot in status new.
    static func newWeightedTransferSlot(_ code: String, name: String) -> WeightedTransferSlot {
        return WeightedTransferSlot(
            code: code,
            name: name,
            payer: "",
            startsAt: 0,
            patientRef: "",
            status: WeightedTransferSlotStatus.new
        )
    }
}
