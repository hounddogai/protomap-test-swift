import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient care protocol bundle is in its life cycle.
    enum LenientCareProtocolBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a lenient care protocol bundle and its current status.
    final class LenientCareProtocolBundle {
        var code: String
        var label: String
        var startsAt: Int
        var checksum: String
        var durationMinutes: Int
        var procedureCode: String
        var description: String
        var locale: String
        var attempts: Int
        var status: LenientCareProtocolBundleStatus

        init(code: String, label: String, startsAt: Int, checksum: String, durationMinutes: Int, procedureCode: String, description: String, locale: String, attempts: Int, status: LenientCareProtocolBundleStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.checksum = checksum
            self.durationMinutes = durationMinutes
            self.procedureCode = procedureCode
            self.description = description
            self.locale = locale
            self.attempts = attempts
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

        func canMoveTo(_ next: LenientCareProtocolBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LenientCareProtocolBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care protocol bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return ((Double(durationMinutes) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientCareProtocolBundle {
            return LenientCareProtocolBundle(
                code: code,
                label: label,
                startsAt: startsAt,
                checksum: checksum,
                durationMinutes: durationMinutes,
                procedureCode: procedureCode,
                description: description,
                locale: locale,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient care protocol bundle in status planned.
    static func newLenientCareProtocolBundle(_ code: String, label: String) -> LenientCareProtocolBundle {
        return LenientCareProtocolBundle(
            code: code,
            label: label,
            startsAt: 0,
            checksum: "",
            durationMinutes: 0,
            procedureCode: "",
            description: "",
            locale: "",
            attempts: 0,
            status: LenientCareProtocolBundleStatus.planned
        )
    }
}
