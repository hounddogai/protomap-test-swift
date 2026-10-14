import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling care gap bundle is in its life cycle.
    enum RollingCareGapBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling care gap bundle. Its code is unique within a tenant.
    final class RollingCareGapBundle {
        var code: String
        var title: String
        var margin: Double
        var locale: String
        var ratio: Double
        var priority: Int
        var name: String
        var status: RollingCareGapBundleStatus

        init(code: String, title: String, margin: Double, locale: String, ratio: Double, priority: Int, name: String, status: RollingCareGapBundleStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.locale = locale
            self.ratio = ratio
            self.priority = priority
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingCareGapBundleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingCareGapBundleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareGapBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care gap bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((ratio + margin) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareGapBundle {
            return RollingCareGapBundle(
                code: code,
                title: title,
                margin: margin,
                locale: locale,
                ratio: ratio,
                priority: priority,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling care gap bundle in status created.
    static func newRollingCareGapBundle(_ code: String, title: String) -> RollingCareGapBundle {
        return RollingCareGapBundle(
            code: code,
            title: title,
            margin: 0.0,
            locale: "",
            ratio: 0.0,
            priority: 0,
            name: "",
            status: RollingCareGapBundleStatus.created
        )
    }
}
