import AcmePlatform
import Foundation

extension Consent {
    /// Where a default disclosure window is in its life cycle.
    enum DefaultDisclosureWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default disclosure window as the disclosure team keeps it.
    final class DefaultDisclosureWindow {
        var code: String
        var title: String
        var archived: Bool
        var active: Bool
        var capacity: Int
        var category: String
        var approved: Bool
        var startsAt: Int
        var status: DefaultDisclosureWindowStatus

        init(code: String, title: String, archived: Bool, active: Bool, capacity: Int, category: String, approved: Bool, startsAt: Int, status: DefaultDisclosureWindowStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.active = active
            self.capacity = capacity
            self.category = category
            self.approved = approved
            self.startsAt = startsAt
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

        func canMoveTo(_ next: DefaultDisclosureWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
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
                return next == DefaultDisclosureWindowStatus.done || next == DefaultDisclosureWindowStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: DefaultDisclosureWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default disclosure window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return ((Double(capacity) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultDisclosureWindow {
            return DefaultDisclosureWindow(
                code: code,
                title: title,
                archived: archived,
                active: active,
                capacity: capacity,
                category: category,
                approved: approved,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default disclosure window in status new.
    static func newDefaultDisclosureWindow(_ code: String, title: String) -> DefaultDisclosureWindow {
        return DefaultDisclosureWindow(
            code: code,
            title: title,
            archived: false,
            active: false,
            capacity: 0,
            category: "",
            approved: false,
            startsAt: 0,
            status: DefaultDisclosureWindowStatus.new
        )
    }
}
