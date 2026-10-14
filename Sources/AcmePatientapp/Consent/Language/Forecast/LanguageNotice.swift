import AcmePlatform
import Foundation

extension Consent {
    /// Where a language notice is in its life cycle.
    enum LanguageNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One language notice, with what the planners need to act on it.
    final class LanguageNotice {
        var code: String
        var title: String
        var budget: Double
        var capacity: Int
        var startsAt: Int
        var endsAt: Int
        var diagnosisCode: String
        var batchSize: Int
        var dosageMg: Double
        var status: LanguageNoticeStatus

        init(code: String, title: String, budget: Double, capacity: Int, startsAt: Int, endsAt: Int, diagnosisCode: String, batchSize: Int, dosageMg: Double, status: LanguageNoticeStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.capacity = capacity
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.diagnosisCode = diagnosisCode
            self.batchSize = batchSize
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: LanguageNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LanguageNoticeStatus.running || next == LanguageNoticeStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LanguageNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return (Double(startsAt) * budget * 100).rounded() / 100
        }

        func copyValue() -> LanguageNotice {
            return LanguageNotice(
                code: code,
                title: title,
                budget: budget,
                capacity: capacity,
                startsAt: startsAt,
                endsAt: endsAt,
                diagnosisCode: diagnosisCode,
                batchSize: batchSize,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a language notice in status new.
    static func newLanguageNotice(_ code: String, title: String) -> LanguageNotice {
        return LanguageNotice(
            code: code,
            title: title,
            budget: 0.0,
            capacity: 0,
            startsAt: 0,
            endsAt: 0,
            diagnosisCode: "",
            batchSize: 0,
            dosageMg: 0.0,
            status: LanguageNoticeStatus.new
        )
    }
}
