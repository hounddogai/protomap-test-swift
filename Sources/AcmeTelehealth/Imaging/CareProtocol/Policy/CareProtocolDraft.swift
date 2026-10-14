import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol draft is in its life cycle.
    enum CareProtocolDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care protocol draft as the care protocol team keeps it.
    final class CareProtocolDraft {
        var code: String
        var name: String
        var durationMinutes: Int
        var copay: Double
        var budget: Double
        var priority: Int
        var floorValue: Double
        var quantity: Int
        var status: CareProtocolDraftStatus

        init(code: String, name: String, durationMinutes: Int, copay: Double, budget: Double, priority: Int, floorValue: Double, quantity: Int, status: CareProtocolDraftStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.budget = budget
            self.priority = priority
            self.floorValue = floorValue
            self.quantity = quantity
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

        func canMoveTo(_ next: CareProtocolDraftStatus) -> Bool {
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
                return next == CareProtocolDraftStatus.done || next == CareProtocolDraftStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CareProtocolDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol draft") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(quantity) + budget) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolDraft {
            return CareProtocolDraft(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                copay: copay,
                budget: budget,
                priority: priority,
                floorValue: floorValue,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol draft in status new.
    static func newCareProtocolDraft(_ code: String, name: String) -> CareProtocolDraft {
        return CareProtocolDraft(
            code: code,
            name: name,
            durationMinutes: 0,
            copay: 0.0,
            budget: 0.0,
            priority: 0,
            floorValue: 0.0,
            quantity: 0,
            status: CareProtocolDraftStatus.new
        )
    }
}
