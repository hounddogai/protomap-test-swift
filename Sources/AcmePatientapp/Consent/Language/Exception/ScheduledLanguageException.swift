import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled language exception is in its life cycle.
    enum ScheduledLanguageExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a scheduled language exception and its current status.
    final class ScheduledLanguageException {
        var code: String
        var label: String
        var unit: String
        var startsAt: Int
        var phone: String
        var checksum: String
        var category: String
        var refills: Int
        var pinned: Bool
        var status: ScheduledLanguageExceptionStatus

        init(code: String, label: String, unit: String, startsAt: Int, phone: String, checksum: String, category: String, refills: Int, pinned: Bool, status: ScheduledLanguageExceptionStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.startsAt = startsAt
            self.phone = phone
            self.checksum = checksum
            self.category = category
            self.refills = refills
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledLanguageExceptionStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledLanguageExceptionStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledLanguageExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled language exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return ((Double(refills) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledLanguageException {
            return ScheduledLanguageException(
                code: code,
                label: label,
                unit: unit,
                startsAt: startsAt,
                phone: phone,
                checksum: checksum,
                category: category,
                refills: refills,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled language exception in status idle.
    static func newScheduledLanguageException(_ code: String, label: String) -> ScheduledLanguageException {
        return ScheduledLanguageException(
            code: code,
            label: label,
            unit: "",
            startsAt: 0,
            phone: "",
            checksum: "",
            category: "",
            refills: 0,
            pinned: false,
            status: ScheduledLanguageExceptionStatus.idle
        )
    }
}
