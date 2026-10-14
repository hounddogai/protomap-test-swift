import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual result baseline is in its life cycle.
    enum ManualResultBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One manual result baseline, with what the planners need to act on it.
    final class ManualResultBaseline {
        var code: String
        var name: String
        var locale: String
        var facility: String
        var archived: Bool
        var batchSize: Int
        var active: Bool
        var status: ManualResultBaselineStatus

        init(code: String, name: String, locale: String, facility: String, archived: Bool, batchSize: Int, active: Bool, status: ManualResultBaselineStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.facility = facility
            self.archived = archived
            self.batchSize = batchSize
            self.active = active
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

        func canMoveTo(_ next: ManualResultBaselineStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ManualResultBaselineStatus.done
            case .running:
                return next == ManualResultBaselineStatus.done || next == ManualResultBaselineStatus.failed
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

        func moveTo(_ next: ManualResultBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual result baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> ManualResultBaseline {
            return ManualResultBaseline(
                code: code,
                name: name,
                locale: locale,
                facility: facility,
                archived: archived,
                batchSize: batchSize,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual result baseline in status new.
    static func newManualResultBaseline(_ code: String, name: String) -> ManualResultBaseline {
        return ManualResultBaseline(
            code: code,
            name: name,
            locale: "",
            facility: "",
            archived: false,
            batchSize: 0,
            active: false,
            status: ManualResultBaselineStatus.new
        )
    }
}
