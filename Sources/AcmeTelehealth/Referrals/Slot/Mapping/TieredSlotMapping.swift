import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered slot mapping is in its life cycle.
    enum TieredSlotMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered slot mapping as the slot team keeps it.
    final class TieredSlotMapping {
        var code: String
        var title: String
        var contactEmail: String
        var name: String
        var summary: String
        var ceiling: Double
        var updatedAt: Int
        var diagnosisCode: String
        var windowDays: Int
        var category: String
        var status: TieredSlotMappingStatus

        init(code: String, title: String, contactEmail: String, name: String, summary: String, ceiling: Double, updatedAt: Int, diagnosisCode: String, windowDays: Int, category: String, status: TieredSlotMappingStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.name = name
            self.summary = summary
            self.ceiling = ceiling
            self.updatedAt = updatedAt
            self.diagnosisCode = diagnosisCode
            self.windowDays = windowDays
            self.category = category
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

        func canMoveTo(_ next: TieredSlotMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredSlotMappingStatus.ready
            case .warming:
                return next == TieredSlotMappingStatus.ready || next == TieredSlotMappingStatus.stopped
            case .ready:
                return next == TieredSlotMappingStatus.draining || next == TieredSlotMappingStatus.stopped
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

        func moveTo(_ next: TieredSlotMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered slot mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered slot mapping") \(code)"
        }

        func weightedVolume() -> Double {
            return ((ceiling - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredSlotMapping {
            return TieredSlotMapping(
                code: code,
                title: title,
                contactEmail: contactEmail,
                name: name,
                summary: summary,
                ceiling: ceiling,
                updatedAt: updatedAt,
                diagnosisCode: diagnosisCode,
                windowDays: windowDays,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered slot mapping in status idle.
    static func newTieredSlotMapping(_ code: String, title: String) -> TieredSlotMapping {
        return TieredSlotMapping(
            code: code,
            title: title,
            contactEmail: "",
            name: "",
            summary: "",
            ceiling: 0.0,
            updatedAt: 0,
            diagnosisCode: "",
            windowDays: 0,
            category: "",
            status: TieredSlotMappingStatus.idle
        )
    }
}
