import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol slot is in its life cycle.
    enum CareProtocolSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One care protocol slot, with what the planners need to act on it.
    final class CareProtocolSlot {
        var code: String
        var title: String
        var score: Double
        var dosageMg: Double
        var windowDays: Int
        var cost: Double
        var version: Int
        var externalRef: String
        var status: CareProtocolSlotStatus

        init(code: String, title: String, score: Double, dosageMg: Double, windowDays: Int, cost: Double, version: Int, externalRef: String, status: CareProtocolSlotStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.cost = cost
            self.version = version
            self.externalRef = externalRef
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

        func canMoveTo(_ next: CareProtocolSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolSlotStatus.running || next == CareProtocolSlotStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareProtocolSlotStatus.done || next == CareProtocolSlotStatus.failed
            case .done:
                return next == CareProtocolSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedExposure() -> Double {
            return (cost * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolSlot {
            return CareProtocolSlot(
                code: code,
                title: title,
                score: score,
                dosageMg: dosageMg,
                windowDays: windowDays,
                cost: cost,
                version: version,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol slot in status new.
    static func newCareProtocolSlot(_ code: String, title: String) -> CareProtocolSlot {
        return CareProtocolSlot(
            code: code,
            title: title,
            score: 0.0,
            dosageMg: 0.0,
            windowDays: 0,
            cost: 0.0,
            version: 0,
            externalRef: "",
            status: CareProtocolSlotStatus.new
        )
    }
}
