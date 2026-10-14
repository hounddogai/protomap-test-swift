import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered dispense notice is in its life cycle.
    enum TieredDispenseNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered dispense notice, with what the planners need to act on it.
    final class TieredDispenseNotice {
        var code: String
        var name: String
        var pinned: Bool
        var label: String
        var source: String
        var expiresAt: Int
        var facility: String
        var visitMinutes: Int
        var category: String
        var unit: String
        var status: TieredDispenseNoticeStatus

        init(code: String, name: String, pinned: Bool, label: String, source: String, expiresAt: Int, facility: String, visitMinutes: Int, category: String, unit: String, status: TieredDispenseNoticeStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.label = label
            self.source = source
            self.expiresAt = expiresAt
            self.facility = facility
            self.visitMinutes = visitMinutes
            self.category = category
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredDispenseNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == TieredDispenseNoticeStatus.resolved
            case .resolved:
                return next == TieredDispenseNoticeStatus.reopened || next == TieredDispenseNoticeStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: TieredDispenseNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered dispense notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return ((Double(expiresAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredDispenseNotice {
            return TieredDispenseNotice(
                code: code,
                name: name,
                pinned: pinned,
                label: label,
                source: source,
                expiresAt: expiresAt,
                facility: facility,
                visitMinutes: visitMinutes,
                category: category,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered dispense notice in status open.
    static func newTieredDispenseNotice(_ code: String, name: String) -> TieredDispenseNotice {
        return TieredDispenseNotice(
            code: code,
            name: name,
            pinned: false,
            label: "",
            source: "",
            expiresAt: 0,
            facility: "",
            visitMinutes: 0,
            category: "",
            unit: "",
            status: TieredDispenseNoticeStatus.`open`
        )
    }
}
