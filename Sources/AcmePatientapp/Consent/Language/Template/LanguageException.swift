import AcmePlatform
import Foundation

extension Consent {
    /// Where a language exception is in its life cycle.
    enum LanguageExceptionStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a language exception and its current status.
    final class LanguageException {
        var code: String
        var title: String
        var region: String
        var timezone: String
        var limit: Int
        var durationMinutes: Int
        var windowDays: Int
        var approved: Bool
        var source: String
        var diagnosisCode: String
        var locale: String
        var status: LanguageExceptionStatus

        init(code: String, title: String, region: String, timezone: String, limit: Int, durationMinutes: Int, windowDays: Int, approved: Bool, source: String, diagnosisCode: String, locale: String, status: LanguageExceptionStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.timezone = timezone
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.approved = approved
            self.source = source
            self.diagnosisCode = diagnosisCode
            self.locale = locale
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

        func canMoveTo(_ next: LanguageExceptionStatus) -> Bool {
            switch status {
            case .new:
                return next == LanguageExceptionStatus.queued
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LanguageExceptionStatus.done || next == LanguageExceptionStatus.failed
            case .done:
                return next == LanguageExceptionStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(windowDays) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageException {
            return LanguageException(
                code: code,
                title: title,
                region: region,
                timezone: timezone,
                limit: limit,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                approved: approved,
                source: source,
                diagnosisCode: diagnosisCode,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a language exception in status new.
    static func newLanguageException(_ code: String, title: String) -> LanguageException {
        return LanguageException(
            code: code,
            title: title,
            region: "",
            timezone: "",
            limit: 0,
            durationMinutes: 0,
            windowDays: 0,
            approved: false,
            source: "",
            diagnosisCode: "",
            locale: "",
            status: LanguageExceptionStatus.new
        )
    }
}
