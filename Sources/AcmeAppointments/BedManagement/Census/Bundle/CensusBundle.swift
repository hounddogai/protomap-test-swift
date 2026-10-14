import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census bundle is in its life cycle.
    enum CensusBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One census bundle, with what the planners need to act on it.
    final class CensusBundle {
        var code: String
        var title: String
        var channel: String
        var active: Bool
        var facility: String
        var bed: String
        var ceiling: Double
        var locale: String
        var maximum: Double
        var status: CensusBundleStatus

        init(code: String, title: String, channel: String, active: Bool, facility: String, bed: String, ceiling: Double, locale: String, maximum: Double, status: CensusBundleStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.active = active
            self.facility = facility
            self.bed = bed
            self.ceiling = ceiling
            self.locale = locale
            self.maximum = maximum
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

        func canMoveTo(_ next: CensusBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CensusBundleStatus.active || next == CensusBundleStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CensusBundleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("census bundle") \(code)"
        }

        func weightedLoad() -> Double {
            return ((maximum - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CensusBundle {
            return CensusBundle(
                code: code,
                title: title,
                channel: channel,
                active: active,
                facility: facility,
                bed: bed,
                ceiling: ceiling,
                locale: locale,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a census bundle in status draft.
    static func newCensusBundle(_ code: String, title: String) -> CensusBundle {
        return CensusBundle(
            code: code,
            title: title,
            channel: "",
            active: false,
            facility: "",
            bed: "",
            ceiling: 0.0,
            locale: "",
            maximum: 0.0,
            status: CensusBundleStatus.draft
        )
    }
}
