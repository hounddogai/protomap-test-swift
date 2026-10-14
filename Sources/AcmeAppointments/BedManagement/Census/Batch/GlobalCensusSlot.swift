import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global census slot is in its life cycle.
    enum GlobalCensusSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global census slot and its current status.
    final class GlobalCensusSlot {
        var code: String
        var title: String
        var visitMinutes: Int
        var locale: String
        var discount: Double
        var category: String
        var status: GlobalCensusSlotStatus

        init(code: String, title: String, visitMinutes: Int, locale: String, discount: Double, category: String, status: GlobalCensusSlotStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.locale = locale
            self.discount = discount
            self.category = category
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

        func canMoveTo(_ next: GlobalCensusSlotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
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
                return next == GlobalCensusSlotStatus.done || next == GlobalCensusSlotStatus.failed
            case .done:
                return next == GlobalCensusSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCensusSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global census slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global census slot") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(visitMinutes) - discount) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCensusSlot {
            return GlobalCensusSlot(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                locale: locale,
                discount: discount,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global census slot in status new.
    static func newGlobalCensusSlot(_ code: String, title: String) -> GlobalCensusSlot {
        return GlobalCensusSlot(
            code: code,
            title: title,
            visitMinutes: 0,
            locale: "",
            discount: 0.0,
            category: "",
            status: GlobalCensusSlotStatus.new
        )
    }
}
