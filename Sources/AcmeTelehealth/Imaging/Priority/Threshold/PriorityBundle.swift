import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority bundle is in its life cycle.
    enum PriorityBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One priority bundle, with what the planners need to act on it.
    final class PriorityBundle {
        var code: String
        var title: String
        var amount: Double
        var attributes: [String: String]
        var visitMinutes: Int
        var source: String
        var status: PriorityBundleStatus

        init(code: String, title: String, amount: Double, attributes: [String: String], visitMinutes: Int, source: String, status: PriorityBundleStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.attributes = attributes
            self.visitMinutes = visitMinutes
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PriorityBundleStatus.completed || next == PriorityBundleStatus.cancelled
            case .completed:
                return next == PriorityBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("priority bundle") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedVolume() -> Double {
            return ((Double(visitMinutes) + amount) * 100).rounded() / 100
        }

        func copyValue() -> PriorityBundle {
            return PriorityBundle(
                code: code,
                title: title,
                amount: amount,
                attributes: attributes,
                visitMinutes: visitMinutes,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a priority bundle in status planned.
    static func newPriorityBundle(_ code: String, title: String) -> PriorityBundle {
        return PriorityBundle(
            code: code,
            title: title,
            amount: 0.0,
            attributes: [:],
            visitMinutes: 0,
            source: "",
            status: PriorityBundleStatus.planned
        )
    }
}
