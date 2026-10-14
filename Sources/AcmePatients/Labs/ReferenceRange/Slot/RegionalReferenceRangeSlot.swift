import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional reference range slot is in its life cycle.
    enum RegionalReferenceRangeSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional reference range slot. Its code is unique within a tenant.
    final class RegionalReferenceRangeSlot {
        var code: String
        var name: String
        var batchSize: Int
        var acuity: Int
        var attempts: Int
        var status: RegionalReferenceRangeSlotStatus

        init(code: String, name: String, batchSize: Int, acuity: Int, attempts: Int, status: RegionalReferenceRangeSlotStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.acuity = acuity
            self.attempts = attempts
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

        func canMoveTo(_ next: RegionalReferenceRangeSlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalReferenceRangeSlotStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RegionalReferenceRangeSlotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalReferenceRangeSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional reference range slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return ((Double(acuity) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalReferenceRangeSlot {
            return RegionalReferenceRangeSlot(
                code: code,
                name: name,
                batchSize: batchSize,
                acuity: acuity,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional reference range slot in status draft.
    static func newRegionalReferenceRangeSlot(_ code: String, name: String) -> RegionalReferenceRangeSlot {
        return RegionalReferenceRangeSlot(
            code: code,
            name: name,
            batchSize: 0,
            acuity: 0,
            attempts: 0,
            status: RegionalReferenceRangeSlotStatus.draft
        )
    }
}
