import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient study metric is in its life cycle.
    enum LenientStudyMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient study metric as the study team keeps it.
    final class LenientStudyMetric {
        var code: String
        var label: String
        var visitMinutes: Int
        var archived: Bool
        var approved: Bool
        var updatedAt: Int
        var locale: String
        var status: LenientStudyMetricStatus

        init(code: String, label: String, visitMinutes: Int, archived: Bool, approved: Bool, updatedAt: Int, locale: String, status: LenientStudyMetricStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.approved = approved
            self.updatedAt = updatedAt
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientStudyMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientStudyMetricStatus.revoked || next == LenientStudyMetricStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LenientStudyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient study metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient study metric") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(visitMinutes) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> LenientStudyMetric {
            return LenientStudyMetric(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                archived: archived,
                approved: approved,
                updatedAt: updatedAt,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient study metric in status requested.
    static func newLenientStudyMetric(_ code: String, label: String) -> LenientStudyMetric {
        return LenientStudyMetric(
            code: code,
            label: label,
            visitMinutes: 0,
            archived: false,
            approved: false,
            updatedAt: 0,
            locale: "",
            status: LenientStudyMetricStatus.requested
        )
    }
}
