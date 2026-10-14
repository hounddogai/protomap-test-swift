import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy program variance is in its life cycle.
    enum LegacyProgramVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One legacy program variance, with what the planners need to act on it.
    final class LegacyProgramVariance {
        var code: String
        var title: String
        var locale: String
        var revision: Int
        var weight: Double
        var status: LegacyProgramVarianceStatus

        init(code: String, title: String, locale: String, revision: Int, weight: Double, status: LegacyProgramVarianceStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.revision = revision
            self.weight = weight
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

        func canMoveTo(_ next: LegacyProgramVarianceStatus) -> Bool {
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
                return next == LegacyProgramVarianceStatus.suspended || next == LegacyProgramVarianceStatus.closed
            case .active:
                return next == LegacyProgramVarianceStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyProgramVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy program variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("legacy program variance") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(revision) - weight) * 100).rounded() / 100
        }

        func copyValue() -> LegacyProgramVariance {
            return LegacyProgramVariance(
                code: code,
                title: title,
                locale: locale,
                revision: revision,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy program variance in status draft.
    static func newLegacyProgramVariance(_ code: String, title: String) -> LegacyProgramVariance {
        return LegacyProgramVariance(
            code: code,
            title: title,
            locale: "",
            revision: 0,
            weight: 0.0,
            status: LegacyProgramVarianceStatus.draft
        )
    }
}
