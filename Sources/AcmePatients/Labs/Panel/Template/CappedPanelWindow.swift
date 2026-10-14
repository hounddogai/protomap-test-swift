import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped panel window is in its life cycle.
    enum CappedPanelWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One capped panel window, with what the planners need to act on it.
    final class CappedPanelWindow {
        var code: String
        var title: String
        var attributes: [String: String]
        var cost: Double
        var ward: String
        var status: CappedPanelWindowStatus

        init(code: String, title: String, attributes: [String: String], cost: Double, ward: String, status: CappedPanelWindowStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.cost = cost
            self.ward = ward
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

        func canMoveTo(_ next: CappedPanelWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
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
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CappedPanelWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedPanelWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped panel window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> CappedPanelWindow {
            return CappedPanelWindow(
                code: code,
                title: title,
                attributes: attributes,
                cost: cost,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped panel window in status new.
    static func newCappedPanelWindow(_ code: String, title: String) -> CappedPanelWindow {
        return CappedPanelWindow(
            code: code,
            title: title,
            attributes: [:],
            cost: 0.0,
            ward: "",
            status: CappedPanelWindowStatus.new
        )
    }
}
